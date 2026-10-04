import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// One bounded, account-scoped local draft. Never contains credentials.
class PhotoDraft {
  const PhotoDraft({
    required this.requestId,
    required this.caption,
    required this.photo,
    this.attempted = false,
  });
  final String requestId;
  final String caption;
  final Uint8List photo;
  final bool attempted;
}

class PhotoDraftStore {
  PhotoDraftStore(this.directory);
  final Directory directory;
  File _file(String owner) {
    if (!RegExp(r'^[a-zA-Z0-9-]{1,80}$').hasMatch(owner)) {
      throw const FormatException('Invalid draft owner');
    }
    return File('${directory.path}/photo-$owner.json');
  }

  Future<PhotoDraft?> read(String owner) async {
    final file = _file(owner);
    if (!await file.exists()) return null;
    if (await file.length() > 3 * 1024 * 1024) {
      throw const FormatException('Draft too large');
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final draft = PhotoDraft(
      requestId: json['requestId'] as String,
      caption: json['caption'] as String,
      photo: base64Decode(json['photo'] as String),
      attempted: json['attempted'] == true,
    );
    _validate(draft);
    return draft;
  }

  void _validate(PhotoDraft draft) {
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(draft.requestId) ||
        draft.caption.runes.length > 500 ||
        draft.photo.length > 2 * 1024 * 1024 ||
        draft.photo.length < 3 ||
        draft.photo[0] != 0xff ||
        draft.photo[1] != 0xd8) {
      throw const FormatException('Invalid draft');
    }
  }

  Future<void> save(String owner, PhotoDraft draft) async {
    _validate(draft);
    final file = _file(owner);
    await directory.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({
        'requestId': draft.requestId,
        'caption': draft.caption,
        'photo': base64Encode(draft.photo),
        'attempted': draft.attempted,
      }),
      flush: true,
    );
    // Atomic replacement on the supported Android/iOS filesystems.
    await temporary.rename(file.path);
  }

  Future<void> clear(String owner) async {
    final file = _file(owner);
    if (await file.exists()) await file.delete();
    final temporary = File('${file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
  }
}
