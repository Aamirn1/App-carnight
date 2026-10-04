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
import 'home_post.dart';
import '../core/platform_actions.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.demo});
  final DemoSession demo;
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    if (backend?.social == null)
      return FeedPage(session: demo, homeLayout: true);
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
      await pushPage<void>(context, AuthPage());
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

  Widget _header() => Column(
    children: [
      StoryRail(),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: NightTheme.panel(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: NightTheme.line(context)),
                ),
                child: Row(
                  children: [
                    for (final entry in [
                      (false, 'Discover'),
                      (true, 'Following'),
                    ])
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: _following == entry.$1
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Colors.transparent,
                            foregroundColor: _following == entry.$1
                                ? Theme.of(context).colorScheme.primary
                                : NightTheme.secondaryText(context),
                            minimumSize: Size(48, 44),
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _busy
                              ? null
                              : () async {
                                  if (entry.$1 &&
                                      BackendScope.of(context)?.account ==
                                          null) {
                                    await pushPage<void>(
                                      context,
                                      AuthPage(),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _following = entry.$1;
                                    _demo = false;
                                  });
                                  _load();
                                },
                          child: Text(
                            entry.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: NightTheme.gradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: IconButton(
                tooltip: 'Find car lovers',
                color: Colors.white,
                onPressed: () => pushPage<void>(context, PeoplePage()),
                icon: Icon(Icons.person_add_alt_1_outlined),
              ),
            ),
          ],
        ),
      ),
      if (_demo)
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 12, 6),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: NightTheme.secondaryText(context)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sample feed',
                  style: TextStyle(fontSize: 11, color: NightTheme.secondaryText(context)),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _demo = false);
                  _load();
                },
                child: Text(
                  'Return online',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      if (_busy && !_demo) LinearProgressIndicator(),
    ],
  );

  Future<void> _comments(CommunityPost p) async {
    if (BackendScope.of(context)?.account == null) {
      await pushPage<void>(context, AuthPage());
      return;
    }
    await pushPage<void>(context, CommentsPage(post: p));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) => _demo
      ? FeedPage(session: widget.demo, homeLayout: true, header: _header())
      : RefreshIndicator(
          onRefresh: () => _load(),
          child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: 16),
            itemCount: _posts.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _header();
              index--;
              if (index == _posts.length)
                return Column(
                  children: [
                    if (_error != null) ...[
                      NightCard(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.public_outlined,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'The community is getting ready',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: NightTheme.secondaryText(context)),
                              ),
                              SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => setState(() => _demo = true),
                                icon: Icon(Icons.photo_library_outlined),
                                label: Text('Explore sample feed'),
                              ),
                              TextButton.icon(
                                onPressed: _busy ? null : () => _load(),
                                icon: Icon(Icons.refresh),
                                label: Text('Try again'),
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
                        child: Text('Explore sample feed'),
                      ),
                    if (_more && _posts.isNotEmpty)
                      TextButton(
                        onPressed: _busy ? null : () => _load(more: true),
                        child: Text('Load more posts'),
                      ),
                  ],
                );
              final p = _posts[index];
              final own = BackendScope.of(context)?.account?.id == p.ownerId;
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: HomePost(
                  key: ValueKey(p.id),
                  id: p.id,
                  author: p.name,
                  subtitle: p.createdAt.split('T').first,
                  caption: p.caption,
                  likes: p.likes,
                  comments: p.comments,
                  liked: p.liked,
                  onLike: _pending.contains(p.id)
                      ? null
                      : () => _action(
                          p.id,
                          () => widget.api.like(p.id, !p.liked),
                        ),
                  onComment: () => _comments(p),
                  onShare: () async {
                    final text = 'Cars Night · ${p.name}\n${p.caption}';
                    if (!await PlatformActions.shareText(text)) {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Post text copied.')),
                        );
                    }
                  },
                  trailing: own
                      ? null
                      : PopupMenuButton<String>(
                          tooltip: 'Post options',
                          icon: Icon(Icons.more_horiz),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'follow',
                              child: Text(p.following ? 'Unfollow' : 'Follow'),
                            ),
                            PopupMenuItem(
                              value: 'message',
                              child: Text('Message request'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'follow')
                              _action(
                                p.id,
                                () =>
                                    widget.api.follow(p.ownerId, !p.following),
                              );
                            else if (p.following)
                              _action(p.id, () async {
                                await widget.api.request(p.ownerId);
                                if (context.mounted)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Request sent. Open Messages.',
                                      ),
                                    ),
                                  );
                              });
                            else
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Follow this person before sending a request.',
                                  ),
                                ),
                              );
                          },
                        ),
                  media: p.images.isEmpty
                      ? SizedBox.shrink()
                      : AspectRatio(
                          aspectRatio: 4 / 5,
                          child: PageView(
                            children: [
                              for (final path in p.images)
                                Image.network(
                                  widget.api.imageUrl(path),
                                  fit: BoxFit.contain,
                                  cacheWidth: widget.demo.dataSaver
                                      ? 480
                                      : 1000,
                                  semanticLabel: 'Full photo by ${p.name}',
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  errorBuilder: (_, error, stack) =>
                                      Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                        ),
                ),
              );
            },
          ),
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
      return PageFrame(
        title: 'Comments',
        children: [InfoNote('Sign in again to continue.')],
      );
    return PageFrame(
      title: 'Comments',
      children: [
        Text(widget.post.caption),
        SizedBox(height: 16),
        TextField(
          controller: _body,
          enabled: !_busy,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(labelText: 'Add a comment'),
        ),
        GradientButton(
          label: 'Post comment',
          onPressed: _busy ? null : _submit,
        ),
        if (_busy) LinearProgressIndicator(),
        if (_error != null) InfoNote(_error!),
        TextButton(
          onPressed: _busy ? null : () => _load(),
          child: Text('Refresh comments'),
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
                    icon: Icon(Icons.delete_outline),
                  )
                : null,
          ),
        if (_more && _rows.isNotEmpty)
          TextButton(
            onPressed: _busy ? null : () => _load(more: true),
            child: Text('More comments'),
          ),
      ],
    );
  }
}
