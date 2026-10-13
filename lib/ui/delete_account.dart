import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';
import '../data/account_cleanup.dart';
import 'components.dart';
import 'remote_photo.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, required this.api});
  final SocialRepository api;
  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}
class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  bool _confirm = false, _busy = false, _deleted = false;
  String? _error;
  @override
  void dispose() { _password.dispose(); super.dispose(); }
  Future<void> _delete() async {
    if (!_confirm || _busy) return;
    if (_password.text.isEmpty) { setState(() => _error = 'Enter your current password.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      final owner = widget.api.me;
      await widget.api.deleteAccount(_password.text);
      if (mounted) _password.clear();
      _deleted = true;
      // Cleanup of this device is separate from the successful server deletion.
      try {
        await AccountCleanup.mark(owner);
        await AccountCleanup.retry(clearCache: PhotoCache.manager.emptyCache);
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) { /* Confirmed deletion cleanup retries from its journal at startup. */ }
      if (widget.api.client.auth.currentUser?.id == owner) await widget.api.client.auth.signOut(scope: SignOutScope.local);
      if (mounted) setState(() => _busy = false);
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = _deleted ? 'Your account was deleted. Sign out of this device to finish.' : serviceError(e); });
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: PageFrame(
    title: 'Delete app account',
    children: [
      Text('This cannot be undone',style:Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height:12),
      const Text('Your app profile, posts, comments, saved items and app conversations will be removed. Published photos are queued for deletion. Already downloaded or cached copies may remain outside Cars Night.'),
      const SizedBox(height:12),
      const InfoNote('This deletes your Cars Night app sign-in account. Existing website accounts, listings and transactions are separate and will not be deleted.'),
      const SizedBox(height:12),
      if (!_deleted) ...[
        TextField(controller:_password,enabled:!_busy,obscureText:true,maxLength:1024,decoration:const InputDecoration(labelText:'Current password',counterText:'')),
        CheckboxListTile(value:_confirm,onChanged:_busy?null:(value)=>setState(()=>_confirm=value??false),title:const Text('I understand and want to permanently delete my app account'),controlAffinity:ListTileControlAffinity.leading,contentPadding:EdgeInsets.zero),
        FilledButton(style:FilledButton.styleFrom(backgroundColor:Theme.of(context).colorScheme.error,foregroundColor:Theme.of(context).colorScheme.onError),onPressed:_confirm&&!_busy?_delete:null,child:Text(_busy?'Deleting…':'Permanently delete app account')),
      ],
      if (_error!=null) InfoNote(_error!),
      if (_deleted) const Text('Your app account has been deleted.'),
    ],
  ));
}
