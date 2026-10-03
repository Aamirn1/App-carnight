import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../backend/session.dart';
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
  bool _recovering = true;

  @override
  void initState() {
    super.initState();
    _recover();
  }

  Future<void> _recover() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final lost = await _picker.retrieveLostData();
        if (lost.files?.isNotEmpty == true) await _accept(lost.files!.first);
        if (lost.exception != null && mounted) {
          setState(() => _error = 'The photo could not be recovered. Choose it again.');
        }
      }
    } catch (_) {
      // A normal new selection remains available after a recovery failure.
    } finally {
      if (mounted) setState(() => _recovering = false);
    }
  }

  Future<void> _accept(XFile file) async {
    if (await file.length() > 2 * 1024 * 1024) {
      throw const FormatException('Choose a smaller photo (under 2 MB after resizing).');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length < 3 || bytes[0] != 0xff || bytes[1] != 0xd8) {
      throw const FormatException('Choose a JPEG photo. Videos, GIFs and other formats are not supported yet.');
    }
    if (mounted) setState(() {
      _photo = bytes;
      _request = const Uuid().v4();
      _error = null;
    });
  }

  Future<void> _choose() async {
    setState(() { _busy = true; _error = null; });
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440, maxHeight: 1440, imageQuality: 78,
        requestFullMetadata: false,
      );
      if (file != null) await _accept(file);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open this photo. Check photo access and try again.');
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
      setState(() => _error = 'Choose a JPEG photo and add a caption of 1–500 characters.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final response = await api.client.functions.invoke('cn-publish-photo', body: {
        'request_id': _request,
        'caption': caption,
        'image': base64Encode(_photo!),
      });
      if (response.status != 200 || response.data is! Map || response.data['post_id'] == null) {
        throw const FormatException('Publishing is unavailable. Try again with the same photo.');
      }
      if (!mounted || BackendScope.of(context)?.account?.id != widget.ownerId) return;
      Navigator.pop(context, true);
    } on FunctionException catch (e) {
      final code = e.details is Map ? e.details['code'] : null;
      final message = switch (code) {
        'setup' => 'Photo publishing is awaiting server setup.',
        'quota' => 'The photo posting limit has been reached. Please try later.',
        'invalid_image' => 'This photo could not be processed. Choose a JPEG photo under 2 MB.',
        'invalid_caption' => 'Add a caption of 1–500 characters.',
        'unauthorized' => 'Please sign in again before publishing.',
        'conflict' => 'This retry does not match the previous photo. Choose the photo again.',
        _ => e.status == 404
          ? 'Photo publishing is awaiting server setup.'
          : 'Publishing did not finish. Keep this page open and retry.',
      };
      if (mounted) setState(() => _error = message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not confirm publication. Retry with the same photo to avoid duplicates.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() { _caption.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (BackendScope.of(context)?.account?.id != widget.ownerId) {
      return const PageFrame(title: 'Create', children: [InfoNote('Sign in to your account to create a post.')]);
    }
    return PopScope(
      canPop: !_busy,
      child: PageFrame(title: 'Share a photo', children: [
        Text('Your car. Your story.', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('One JPEG photo per post. Photos and captions are public when published.',
          style: TextStyle(color: NightTheme.muted)),
        const SizedBox(height: 16),
        if (_photo != null) ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(_photo!, height: 260, fit: BoxFit.contain, cacheWidth: 720,
            errorBuilder: (_, error, stack) => const InfoNote('Photo preview unavailable. Choose another photo.')),
        ),
        OutlinedButton.icon(
          onPressed: _busy || _recovering ? null : _choose,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(_photo == null ? 'Choose photo' : 'Change photo'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _caption, enabled: !_busy, maxLength: 500, minLines: 3, maxLines: 6,
          decoration: const InputDecoration(labelText: 'Tell us about the photo'),
          onChanged: (_) => _request = const Uuid().v4(),
        ),
        if (_error != null) InfoNote(_error!),
        const SizedBox(height: 16),
        if (_busy) const LinearProgressIndicator(),
        GradientButton(label: _busy ? 'Please wait…' : 'Publish photo',
          onPressed: _busy || _recovering || _photo == null ? null : _publish),
        const SizedBox(height: 12),
        const Text('Share photos you have permission to post. Avoid sharing personal details. '
          'Your selection stays on this page until you publish or leave.',
          style: TextStyle(color: NightTheme.muted, fontSize: 12)),
      ]),
    );
  }
}
