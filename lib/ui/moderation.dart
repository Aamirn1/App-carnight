import 'package:flutter/material.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';

class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key, required this.api});
  final SocialRepository api;
  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  List<Map<String, dynamic>> _reports = [];
  String? _error;
  bool _busy = true;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _busy = true; _error = null; });
    try {
      final reports = await widget.api.moderationQueue();
      if (mounted) setState(() => _reports = reports);
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(Map<String, dynamic> report, bool remove) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: Text(remove ? 'Remove reported post?' : 'Dismiss report?'),
      content: TextField(controller: controller, maxLength: 500, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Review note', hintText: 'Required for the private audit record')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
        TextButton(onPressed: () {
          if (controller.text.trim().isNotEmpty) Navigator.pop(dialog, controller.text.trim());
        }, child: Text(remove ? 'Remove post' : 'Dismiss')),
      ],
    ));
    // Dispose after dialog transition completes to avoid a controller still in use.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.reviewReport(report['id'] as String, remove ? 'removed' : 'dismissed', note);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) setState(() { _error = serviceError(e); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Moderation queue'), actions: [IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh reports')]),
    body: _busy ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_error!)),
        if (_reports.isEmpty && _error == null) const Text('No reports awaiting review.'),
        for (final report in _reports) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report['reason'] as String, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(report['caption'] as String? ?? 'Account report or post no longer available.'),
            for (final path in (report['images'] as List<dynamic>? ?? []))
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Image.network(widget.api.imageUrl(path as String), height: 220, fit: BoxFit.contain, cacheWidth: 720, errorBuilder: (_, _, _) => const Text('Photo unavailable. Refresh before deciding.'))),
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              TextButton(onPressed: () => _review(report, false), child: const Text('Dismiss')),
              if (report['target_post_id'] != null) TextButton(onPressed: () => _review(report, true), child: const Text('Remove post')),
            ]),
          ],
        ))),
        if (_reports.length == 50) const Text('Showing the oldest 50 reports. Review these and refresh to see more.'),
      ],
    ),
  );
}
