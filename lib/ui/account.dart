import 'package:flutter/material.dart';
import '../backend/repositories.dart';
import '../backend/session.dart';
import '../backend/supabase_repositories.dart';
import 'auth.dart';
import 'components.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;
  String? _error;
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    final account = backend?.account;
    if (account == null) return const AuthPage();
    return PageFrame(title: 'Your account', children: [
      Text(account.displayName, style: Theme.of(context).textTheme.headlineSmall),
      const InfoNote('Private drafts are stored with your account. '
          'Image uploads and public publishing are coming in the next increment.'),
      for (final kind in DraftKind.values)
        ListTile(leading: const Icon(Icons.edit_note),
          title: Text(switch (kind) { DraftKind.post => 'Post drafts',
            DraftKind.sale => 'Sale listing drafts', DraftKind.rental => 'Rental listing drafts' }),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => pushPage<void>(context, DraftsPage(
            // Account changes dispose the old draft view and its pending UI results.
            key: ValueKey(account.id), kind: kind, ownerId: account.id))),
      if (_error != null) InfoNote(_error!),
      const SizedBox(height: 16),
      OutlinedButton(onPressed: _busy ? null : () async {
        setState(() { _busy = true; _error = null; });
        try { await backend!.accounts.signOut(); }
        catch (error) { if (mounted) _error = serviceError(error); }
        finally { if (mounted) setState(() => _busy = false); }
      }, child: Text(_busy ? 'Signing out…' : 'Sign out of this device')),
    ]);
  }
}

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key, required this.kind, required this.ownerId});
  final DraftKind kind;
  final String ownerId;
  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  final List<ContentDraft> _items = [];
  bool _busy = false;
  bool _more = true;
  bool _started = false;
  String? _error;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load(reset: true);
    }
  }

  Future<void> _load({bool reset = false}) async {
    final backend = BackendScope.of(context);
    if (_busy || backend?.account?.id != widget.ownerId) return;
    final request = ++_request;
    setState(() { _busy = true; _error = null; if (reset) _items.clear(); });
    try {
      final page = await backend!.drafts.load(widget.kind, offset: _items.length);
      if (!mounted || request != _request || backend.account?.id != widget.ownerId) return;
      setState(() { _items.addAll(page); _more = page.length == 20; });
    } catch (error) {
      if (mounted && request == _request) setState(() => _error = serviceError(error));
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _edit([ContentDraft? draft]) async {
    final changed = await pushPage<bool>(context,
        DraftEditor(kind: widget.kind, ownerId: widget.ownerId, draft: draft));
    if (mounted && changed == true) await _load(reset: true);
  }

  Future<void> _delete(ContentDraft draft) async {
    final backend = BackendScope.of(context);
    final confirmed = await showDialog<bool>(context: context, builder: (context) =>
      AlertDialog(title: const Text('Delete this draft?'),
        content: const Text('This permanently removes the draft from your account.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (!mounted || confirmed != true || _busy || backend?.account?.id != widget.ownerId) return;
    setState(() { _busy = true; _error = null; });
    try {
      await backend!.drafts.delete(draft);
      if (!mounted) return;
      setState(() => _busy = false);
      await _load(reset: true);
    } catch (error) {
      if (mounted) setState(() { _busy = false; _error = serviceError(error); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (BackendScope.of(context)?.account?.id != widget.ownerId) {
      return const PageFrame(title: 'Private drafts', children: [
        InfoNote('Your session changed. Return to your account to continue.')]);
    }
    return PageFrame(title: 'Private drafts', children: [
      GradientButton(label: 'New draft', onPressed: _busy ? null : () => _edit()),
      const InfoNote('Drafts are visible only to you. They do not appear in the public feed.'),
      if (_error != null) ...[Semantics(liveRegion: true, child: InfoNote(_error!)),
        TextButton(onPressed: _busy ? null : () => _load(reset: true), child: const Text('Retry'))],
      if (!_busy && _error == null && _items.isEmpty)
        const EmptyState(title: 'No drafts yet', message: 'Save an idea for a post or listing.'),
      for (final draft in _items) ListTile(
        title: Text(draft.text, maxLines: 3, overflow: TextOverflow.ellipsis),
        subtitle: draft.kind == DraftKind.post ? null : Text('${draft.city} · ${draft.currency} ${(draft.priceMinor! / 100).toStringAsFixed(2)}'),
        onTap: _busy ? null : () => _edit(draft),
        trailing: IconButton(tooltip: 'Delete draft', onPressed: _busy ? null : () => _delete(draft),
            icon: const Icon(Icons.delete_outline))),
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (!_busy && _items.isNotEmpty) ...[
        if (_more) TextButton(onPressed: () => _load(), child: const Text('Load more')),
        TextButton(onPressed: () => _load(reset: true), child: const Text('Refresh')),
      ],
    ]);
  }
}

class DraftEditor extends StatefulWidget {
  const DraftEditor({super.key, required this.kind, required this.ownerId, this.draft});
  final DraftKind kind;
  final String ownerId;
  final ContentDraft? draft;
  @override
  State<DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<DraftEditor> {
  final _form = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.draft?.text);
  late final _city = TextEditingController(text: widget.draft?.city);
  late final _price = TextEditingController(text: widget.draft?.priceMinor == null ? '' :
      (widget.draft!.priceMinor! / 100).toStringAsFixed(2));
  late String _currency = widget.draft?.currency ?? 'USD';
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _text.dispose(); _city.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _save() async {
    final backend = BackendScope.of(context);
    if (_busy || backend?.account?.id != widget.ownerId || !_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await backend!.drafts.save(kind: widget.kind, id: widget.draft?.id, text: _text.text,
        city: _city.text, currency: _currency, priceMinor: parseDraftPrice(_price.text));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = serviceError(error));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (BackendScope.of(context)?.account?.id != widget.ownerId) {
      return const PageFrame(title: 'Draft', children: [InfoNote('Sign in again to continue.')]);
    }
    final post = widget.kind == DraftKind.post;
    return PageFrame(title: widget.draft == null ? 'New draft' : 'Edit draft', children: [
      Form(key: _form, child: Column(children: [
        TextFormField(controller: _text, maxLength: post ? 500 : 80, maxLines: post ? 5 : 2,
          decoration: InputDecoration(labelText: post ? 'Caption' : 'Listing title'),
          validator: (value) => (value ?? '').trim().isEmpty ? 'Enter some text.' : null),
        if (!post) ...[
          TextFormField(controller: _city, maxLength: 80, decoration: const InputDecoration(labelText: 'City'),
            validator: (value) => (value ?? '').trim().isEmpty ? 'Enter a city.' : null),
          DropdownButtonFormField<String>(initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: { _currency, 'USD', 'PKR', 'AED', 'GBP', 'EUR', 'INR', 'SAR' }.map((value) =>
              DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: _busy ? null : (value) => setState(() => _currency = value!)),
          const SizedBox(height: 16),
          TextFormField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: widget.kind == DraftKind.rental ? 'Daily price' : 'Price'),
            validator: (value) => parseDraftPrice(value ?? '') == null ? 'Enter a positive price, up to 2 decimal places.' : null),
        ],
      ])),
      const InfoNote('This saves text details only. Images and publishing are not enabled yet.'),
      if (_error != null) Semantics(liveRegion: true, child: InfoNote(_error!)),
      GradientButton(label: _busy ? 'Saving…' : 'Save private draft', onPressed: _busy ? null : _save),
    ]);
  }
}

int? parseDraftPrice(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final minor = int.parse(parts[0]) * 100 + (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  return minor > 0 ? minor : null;
}
