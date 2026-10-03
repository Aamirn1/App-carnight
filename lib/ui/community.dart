import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../backend/session.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'auth.dart';
import 'components.dart';
import 'feed.dart';
import 'messages.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.demo});
  final DemoSession demo;
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    if (backend?.social == null) return FeedPage(session: demo);
    return _Community(
      key: ValueKey(backend?.account?.id ?? 'guest'),
      api: backend!.social!,
      demo: demo,
    );
  }
}

class _Community extends StatefulWidget {
  const _Community({super.key, required this.api, required this.demo});
  final SocialRepository api;
  final DemoSession demo;
  @override
  State<_Community> createState() => _CommunityState();
}

class _CommunityState extends State<_Community> {
  final List<CommunityPost> _posts = [];
  final Set<String> _pending = {};
  bool _following = false, _busy = false, _more = true, _demo = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await widget.api.feed(
        following: _following,
        before: more && _posts.isNotEmpty ? _posts.last : null,
      );
      if (mounted)
        setState(() {
          if (!more) _posts.clear();
          _posts.addAll(rows);
          _more = rows.length == 20;
        });
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String id, Future<void> Function() action) async {
    if (BackendScope.of(context)?.account == null) {
      await pushPage<void>(context, const AuthPage());
      return;
    }
    if (_pending.contains(id)) return;
    setState(() => _pending.add(id));
    try {
      await action();
      if (mounted) await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(serviceError(e))));
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Discover'),
              showCheckmark: false,
              selectedColor: const Color(0xFF302658),
              labelStyle: TextStyle(color: !_following ? NightTheme.cyan : Colors.white),
              selected: !_following,
              onSelected: _busy
                  ? null
                  : (_) {
                      setState(() => _following = false);
                      _load();
                    },
            ),
            ChoiceChip(
              label: const Text('Following'),
              showCheckmark: false,
              selectedColor: const Color(0xFF302658),
              labelStyle: TextStyle(color: _following ? NightTheme.cyan : Colors.white),
              selected: _following,
              onSelected: _busy
                  ? null
                  : (_) async {
                      if (BackendScope.of(context)?.account == null) {
                        await pushPage<void>(context, const AuthPage());
                        return;
                      }
                      setState(() => _following = true);
                      _load();
                    },
            ),
            IconButton(
              tooltip: 'Find car lovers',
              onPressed: () => pushPage<void>(context, const PeoplePage()),
              icon: const Icon(Icons.person_add_alt),
            ),
          ],
        ),
      ),
      if (_demo)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sample feed',
                  style: TextStyle(color: NightTheme.muted),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _demo = false);
                  _load();
                },
                child: const Text('Return online'),
              ),
            ],
          ),
        ),
      if (_busy && !_demo) const LinearProgressIndicator(),
      Expanded(
        child: _demo
            ? FeedPage(session: widget.demo)
            : RefreshIndicator(
                onRefresh: () => _load(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _posts.length)
                      return Column(
                        children: [
                          if (_error != null) ...[
                            NightCard(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.public_outlined, size: 40, color: NightTheme.cyan),
                                    const SizedBox(height: 16),
                                    Text('The community is getting ready',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleLarge),
                                    const SizedBox(height: 12),
                                    Text(_error!, textAlign: TextAlign.center,
                                      style: const TextStyle(color: NightTheme.muted)),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: () => setState(() => _demo = true),
                                      icon: const Icon(Icons.photo_library_outlined),
                                      label: const Text('Explore sample feed'),
                                    ),
                                    TextButton.icon(
                                      onPressed: _busy ? null : () => _load(),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Try again'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_posts.isEmpty && !_busy && _error == null)
                            EmptyState(
                              title: _following
                                  ? 'Your community starts here'
                                  : 'Be part of the first night drive',
                              message: _following
                                  ? 'Follow car lovers to see their published photos here.'
                                  : 'Published photo posts will appear here.',
                              icon: Icons.auto_awesome_outlined,
                            ),
                          if (_posts.isEmpty && !_busy && _error == null)
                            TextButton(
                              onPressed: () => setState(() => _demo = true),
                              child: const Text('Explore sample feed'),
                            ),
                          if (_more && _posts.isNotEmpty)
                            TextButton(
                              onPressed: _busy ? null : () => _load(more: true),
                              child: const Text('Load more posts'),
                            ),
                        ],
                      );
                    final p = _posts[index];
                    final own =
                        BackendScope.of(context)?.account?.id == p.ownerId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: NightCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(p.createdAt.split('T').first),
                              trailing: own
                                  ? null
                                  : TextButton(
                                      onPressed: _pending.contains(p.id)
                                          ? null
                                          : () => _action(
                                              p.id,
                                              () => widget.api.follow(
                                                p.ownerId,
                                                !p.following,
                                              ),
                                            ),
                                      child: Text(
                                        p.following ? 'Following' : 'Follow',
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Text(p.caption),
                            ),
                            if (p.images.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 1.65,
                                child: PageView(
                                  children: [
                                    for (final path in p.images)
                                      Image.network(
                                        widget.api.imageUrl(path),
                                        fit: BoxFit.cover,
                                        cacheWidth: widget.demo.dataSaver
                                            ? 480
                                            : 1000,
                                        loadingBuilder:
                                            (
                                              context,
                                              child,
                                              progress,
                                            ) => progress == null
                                            ? child
                                            : const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                        errorBuilder: (_, error, stack) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            if (p.images.length > 1)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'Swipe · ${p.images.length} photos',
                                  style: const TextStyle(
                                    color: NightTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: p.liked ? 'Unlike' : 'Like',
                                  onPressed: _pending.contains(p.id)
                                      ? null
                                      : () => _action(
                                          p.id,
                                          () => widget.api.like(p.id, !p.liked),
                                        ),
                                  icon: Icon(
                                    p.liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: NightTheme.magenta,
                                  ),
                                ),
                                Text('${p.likes}'),
                                IconButton(
                                  tooltip: 'Comments',
                                  onPressed: () async {
                                    if (BackendScope.of(context)?.account ==
                                        null) {
                                      await pushPage<void>(
                                        context,
                                        const AuthPage(),
                                      );
                                      return;
                                    }
                                    await pushPage<void>(
                                      context,
                                      CommentsPage(post: p),
                                    );
                                    if (mounted) _load();
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                ),
                                Text('${p.comments}'),
                                IconButton(
                                  tooltip: 'Copy post reference',
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            'Cars Night · ${p.name}\n${p.caption}\nPost: ${p.id}',
                                      ),
                                    );
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Post reference copied. Public share links are coming later.',
                                          ),
                                        ),
                                      );
                                  },
                                  icon: const Icon(Icons.share_outlined),
                                ),
                                if (!own)
                                  IconButton(
                                    tooltip: p.following
                                        ? 'Request conversation'
                                        : 'Follow before messaging',
                                    onPressed:
                                        _pending.contains(p.id) || !p.following
                                        ? null
                                        : () => _action(p.id, () async {
                                            await widget.api.request(p.ownerId);
                                            if (context.mounted)
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Request sent. Open Messages → Requests.',
                                                  ),
                                                ),
                                              );
                                          }),
                                    icon: const Icon(Icons.mail_outline),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.post});
  final CommunityPost post;
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _body = TextEditingController();
  final List<Map<String, dynamic>> _rows = [];
  Map<String, String> _names = {};
  bool _busy = false, _more = true;
  String? _error, _owner;
  SocialRepository get _api => BackendScope.of(context)!.social!;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_owner == null) {
      _owner = BackendScope.of(context)?.account?.id;
      if (_owner != null) _load();
    }
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    final api = _api;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await api.comments(
        widget.post.id,
        offset: more ? _rows.length : 0,
      );
      final names = await api.names(
        rows.map((r) => r['user_id'] as String).toList(),
      );
      if (mounted && BackendScope.of(context)?.account?.id == _owner)
        setState(() {
          if (!more) _rows.clear();
          _rows.addAll(rows);
          _names.addAll(names);
          _more = rows.length == 20;
        });
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || _body.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _api.comment(widget.post.id, _body.text);
      if (!mounted) return;
      _body.clear();
      setState(() => _busy = false);
      await _load();
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = serviceError(e);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (BackendScope.of(context)?.account?.id != _owner || _owner == null)
      return const PageFrame(
        title: 'Comments',
        children: [InfoNote('Sign in again to continue.')],
      );
    return PageFrame(
      title: 'Comments',
      children: [
        Text(widget.post.caption),
        const SizedBox(height: 16),
        TextField(
          controller: _body,
          enabled: !_busy,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Add a comment'),
        ),
        GradientButton(
          label: 'Post comment',
          onPressed: _busy ? null : _submit,
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) InfoNote(_error!),
        TextButton(
          onPressed: _busy ? null : () => _load(),
          child: const Text('Refresh comments'),
        ),
        for (final r in _rows)
          ListTile(
            title: Text(_names[r['user_id']] ?? 'Car enthusiast'),
            subtitle: Text(r['body'] as String),
            trailing: r['user_id'] == _owner
                ? IconButton(
                    tooltip: 'Delete comment',
                    onPressed: _busy
                        ? null
                        : () async {
                            try {
                              await _api.deleteComment(r['id'] as String);
                              if (mounted) await _load();
                            } catch (e) {
                              if (mounted)
                                setState(() => _error = serviceError(e));
                            }
                          },
                    icon: const Icon(Icons.delete_outline),
                  )
                : null,
          ),
        if (_more && _rows.isNotEmpty)
          TextButton(
            onPressed: _busy ? null : () => _load(more: true),
            child: const Text('More comments'),
          ),
      ],
    );
  }
}
