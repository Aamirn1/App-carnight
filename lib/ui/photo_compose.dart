import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../backend/session.dart';
import '../data/photo_draft.dart';
import '../core/theme.dart';
import 'components.dart';

/// One photo per post keeps the first online media release inexpensive.
class PhotoComposePage extends StatefulWidget {
  const PhotoComposePage({super.key, required this.ownerId});
  final String ownerId;
  @override
  State<PhotoComposePage> createState() => _PhotoComposePageState();
}

class _PhotoComposePageState extends State<PhotoComposePage> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _photo;
  String _request = const Uuid().v4();
  String? _error;
  bool _busy = false;
  bool _attempted = false;
  String? _draftNote;
  PhotoDraftStore? _store;
  bool _recovering = true;

  @override
  void initState() {
    super.initState();
    _recover();
  }

  Future<void> _recover() async {
    try {
      final root = await getApplicationSupportDirectory();
      _store = PhotoDraftStore(Directory('${root.path}/photo-drafts'));
      final draft = await _store!.read(widget.ownerId);
      if (draft != null && mounted) {
        _photo = draft.photo;
        _caption.text = draft.caption;
        _request = draft.requestId;
        _attempted = draft.attempted;
        _draftNote = 'Saved draft restored.';
      }
      if (!_attempted && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final lost = await _picker.retrieveLostData();
        if (lost.files?.isNotEmpty == true) await _accept(lost.files!.first);
        if (lost.exception != null && mounted) {
          setState(
            () => _error = 'The photo could not be recovered. Choose it again.',
          );
        }
      }
    } catch (_) {
      if (mounted) _error = 'Could not restore the draft. Your saved file has not been removed.';
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  Future<void> _accept(XFile file) async {
    if (await file.length() > 2 * 1024 * 1024) {
      throw const FormatException(
        'Choose a smaller photo (under 2 MB after resizing).',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 3 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const FormatException(
        'Choose a JPEG photo. Videos, GIFs and other formats are not supported yet.',
      );
    }
    if (mounted)
      setState(() {
        _photo = bytes;
        _request = const Uuid().v4();
        _error = null;
        _draftNote = 'Unsaved changes — tap Save draft before leaving.';
      });
  }

  Future<void> _saveDraft() async {
    if (_busy || _photo == null) return;
    setState(() => _busy = true);
    try {
      await _persist();
      if (mounted) setState(() => _draftNote = 'Draft saved on this device.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Keep this page open and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) throw StateError('Draft storage unavailable');
    await store.save(widget.ownerId, PhotoDraft(requestId: _request,
      caption: _caption.text.trim(), photo: _photo!, attempted: _attempted));
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Discard this draft?'),
      content: Text(_attempted
        ? 'Publication may already have succeeded. Check your feed before starting another post. This removes only the local draft.'
        : 'The saved photo and caption will be removed from this device.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep draft')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard'))],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _store?.clear(widget.ownerId);
      if (!mounted) return;
      setState(() { _photo = null; _caption.clear(); _attempted = false;
        _request = const Uuid().v4(); _error = null; _draftNote = null; });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not discard the draft. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 78,
        requestFullMetadata: false,
      );
      if (file != null) await _accept(file);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not open this photo. Check photo access and try again.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    final backend = BackendScope.of(context);
    final api = backend?.social;
    if (_busy || api == null || backend?.account?.id != widget.ownerId) return;
    final caption = _caption.text.trim();
    if (_photo == null || caption.isEmpty || caption.runes.length > 500) {
      setState(
        () => _error =
            'Choose a JPEG photo and add a caption of 1–500 characters.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final previouslyAttempted = _attempted;
    try {
      _attempted = true;
      await _persist();
    } catch (_) {
      if (mounted) setState(() {
        _attempted = previouslyAttempted;
        _busy = false;
        _error = 'Could not save the post for safe retry. Free some device storage and try again.';
      });
      return;
    }
    try {
      // The exact payload is already on disk before any network request.
      if (!mounted || BackendScope.of(context)?.account?.id != widget.ownerId) return;
      final response = await api.client.functions.invoke(
        'cn-publish-photo',
        body: {
          'request_id': _request,
          'caption': caption,
          'image': base64Encode(_photo!),
        },
      );
      if (response.status != 200 ||
          response.data is! Map ||
          response.data['post_id'] == null) {
        throw const FormatException(
          'Publishing is unavailable. Try again with the same photo.',
        );
      }
      if (!mounted || BackendScope.of(context)?.account?.id != widget.ownerId)
        return;
      try {
        await _store?.clear(widget.ownerId);
      } catch (_) {
        // The retained request ID makes a later retry safe even if cleanup fails.
      }
      if (mounted) Navigator.pop(context, true);
    } on FunctionException catch (e) {
      final code = e.details is Map ? e.details['code'] : null;
      final message = switch (code) {
        'setup' => 'Photo publishing is awaiting server setup.',
        'quota' =>
          'The photo posting limit has been reached. Please try later.',
        'invalid_image' =>
          'This photo could not be processed. Choose a JPEG photo under 2 MB.',
        'invalid_caption' => 'Add a caption of 1–500 characters.',
        'unauthorized' => 'Please sign in again before publishing.',
        'conflict' =>
          'This retry differs from the saved post. Check your feed before discarding the draft.',
        _ =>
          e.status == 404
              ? 'Photo publishing is awaiting server setup.'
              : 'Publishing did not finish. Keep this page open and retry.',
      };
      if (mounted) setState(() => _error = message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Could not confirm publication. Retry with the same photo to avoid duplicates.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (BackendScope.of(context)?.account?.id != widget.ownerId) {
      return const PageFrame(
        title: 'Create',
        children: [InfoNote('Sign in to your account to create a post.')],
      );
    }
    return PopScope(
      canPop: !_busy,
      child: PageFrame(
        title: 'Share a photo',
        children: [
          Text(
            'Your car. Your story.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'One JPEG photo per post. Photos and captions are public when published.',
            style: TextStyle(color: NightTheme.muted),
          ),
          const SizedBox(height: 16),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _photo!,
                height: 260,
                fit: BoxFit.contain,
                cacheWidth: 720,
                errorBuilder: (_, error, stack) => const InfoNote(
                  'Photo preview unavailable. Choose another photo.',
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy || _recovering || _attempted ? null : _choose,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_photo == null ? 'Choose photo' : 'Change photo'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _caption,
            enabled: !_busy && !_recovering && !_attempted,
            maxLength: 500,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Tell us about the photo',
            ),
            onChanged: (_) { _request = const Uuid().v4();
              setState(() => _draftNote = 'Unsaved changes — tap Save draft before leaving.'); },
          ),
          if (_draftNote != null) InfoNote(_draftNote!),
          if (_attempted) const InfoNote('Publication is pending confirmation. Retry the same post without creating a duplicate.'),
          if (_error != null) InfoNote(_error!),
          Wrap(spacing: 12, children: [
            TextButton.icon(onPressed: _busy || _recovering || _photo == null ? null : _saveDraft,
              icon: const Icon(Icons.save_outlined), label: const Text('Save draft')),
            TextButton(onPressed: _busy || _recovering ? null : _discard, child: const Text('Discard draft')),
          ]),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          GradientButton(
            label: _busy ? 'Please wait…' : _attempted ? 'Retry publication' : 'Publish photo',
            onPressed: _busy || _recovering || _photo == null ? null : _publish,
          ),
          const SizedBox(height: 12),
          const Text(
            'Share photos you have permission to post. Avoid sharing personal details. '
            'Save your draft before leaving. Saved drafts stay on this device for your account until published or discarded.',
            style: TextStyle(color: NightTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
