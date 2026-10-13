import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';
import '../core/platform_actions.dart';
import 'components.dart';
import 'home_post.dart';
import 'remote_photo.dart';
import 'community.dart';

class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key, required this.api, required this.user});
  final SocialRepository api;
  final String user;
  @override
  Widget build(BuildContext context) => _CollectionPage(api: api, author: user);
}
class OnlineSavedPage extends StatelessWidget {
  const OnlineSavedPage({super.key, required this.api});
  final SocialRepository api;
  @override
  Widget build(BuildContext context) => _CollectionPage(api: api, saved: true);
}
class _CollectionPage extends StatefulWidget {
  const _CollectionPage({required this.api, this.author, this.saved = false});
  final SocialRepository api;
  final String? author;
  final bool saved;
  @override
  State<_CollectionPage> createState() => _CollectionPageState();
}
class _CollectionPageState extends State<_CollectionPage> {
  final _posts = <CommunityPost>[];
  Map<String,dynamic>? _profile;
  bool _busy = true, _more = false, _loading = false, _mutating = false;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load({bool more = false}) async {
    if (_loading || _mutating) return;
    _loading = true;
    setState(() { _busy = true; _error = null; });
    try {
      final profile = widget.author == null ? null : await widget.api.profile(widget.author!);
      final posts = await widget.api.collection(author: widget.author, saved: widget.saved, before: more && _posts.isNotEmpty ? _posts.last : null);
      if (!mounted) return;
      setState(() { _profile = profile; if (!more) _posts.clear(); _posts.addAll(posts); _more = posts.length == 20; });
    } catch (e) { if (mounted) setState(() { _error = serviceError(e); if (e is PostgrestException && e.code == '42501') { _profile = null; _posts.clear(); } }); }
    finally { _loading = false; if (mounted) setState(() => _busy = false); }
  }
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _mutating = true;
    setState(() => _busy = true);
    try { await action(); _mutating = false; if (mounted) await _load(); }
    catch (e) { if (mounted) setState(() => _error = serviceError(e)); }
    finally { _mutating = false; if (mounted) setState(() => _busy = false); }
  }
  Widget _header() {
    final p = _profile;
    if (p == null) return const SizedBox.shrink();
    final name = p['display_name'] as String;
    final following = p['is_following'] == true;
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(radius: 36, child: Text(name.isEmpty ? 'C' : name.characters.first, style: const TextStyle(fontSize: 32))), const SizedBox(width: 16), Expanded(child: Text(name, style: Theme.of(context).textTheme.headlineSmall))]),
      const SizedBox(height: 16),
      Text('${p['followers']} followers · ${p['following']} following · ${p['posts']} posts'),
      if ((p['bio'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(p['bio'] as String)),
      if ((p['city'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('City · ${p['city']}')),
      if ((p['dream_car'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Dream car · ${p['dream_car']}')),
      if (widget.author != widget.api.me) Wrap(spacing: 12, children: [
        FilledButton(onPressed: _busy ? null : () => _run(() => widget.api.follow(widget.author!, !following)), child: Text(following ? 'Following' : 'Follow')),
        OutlinedButton(onPressed: _busy || !following ? null : () => _run(() async {
          await widget.api.request(widget.author!);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent. Open Messages.')));
        }), child: const Text('Message request')),
      ]),
    ]));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.saved ? 'Saved posts' : 'Member profile'), actions: [IconButton(onPressed: _busy ? null : () => _load(), icon: const Icon(Icons.refresh), tooltip: 'Refresh')]),
    body: RefreshIndicator(onRefresh: () => _load(), child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return Column(children: [_header(), if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!))]);
        if (index == _posts.length + 1) return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          if (_busy) const CircularProgressIndicator(),
          if (!_busy && _posts.isEmpty && _error == null) Text(widget.saved ? 'Save a post from Home to find it here.' : 'No public posts yet.'),
          if (!_busy && _more) TextButton(onPressed: () => _load(more: true), child: const Text('Load more')),
        ]));
        final p = _posts[index-1];
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: HomePost(
          id:p.id,author:p.name,subtitle:p.createdAt.split('T').first,caption:p.caption,
          likes:p.likes,comments:p.comments,liked:p.liked,saved:p.saved,
          onLike:_busy ? null : () => _run(() => widget.api.like(p.id,!p.liked)),
          onSave:_busy ? null : () => _run(() => widget.api.savePost(p.id,!p.saved)),
          onComment:() => pushPage<void>(context, CommentsPage(post:p)),
          onShare:() async {final text='Cars Night · ${p.name}\n${p.caption}${p.images.isEmpty ? '' : '\nPhoto: ${widget.api.imageUrl(p.images.first)}'}'; if(!await PlatformActions.shareText(text)) await Clipboard.setData(ClipboardData(text:text));},
          media:p.images.isEmpty ? const SizedBox.shrink() : GestureDetector(
            onTap:() => pushPage<void>(context, PhotoDetailPage(url:widget.api.imageUrl(p.images.first),caption:p.caption)),
            child:AspectRatio(aspectRatio:4/5,child:RemotePhoto(url:widget.api.imageUrl(p.thumbnails.isEmpty?p.images.first:p.thumbnails.first))),
          ),
        ));
      },
    )),
  );
}
