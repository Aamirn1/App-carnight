import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../backend/session.dart';
import '../backend/social.dart';
import '../backend/supabase_repositories.dart';
import '../core/theme.dart';
import 'auth.dart';
import 'components.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    if (backend?.account == null || backend?.social == null) {
      return ListView(
        padding: EdgeInsets.all(20),
        children: [
          Text('Messages', style: Theme.of(context).textTheme.headlineMedium),
          EmptyState(
            title: 'Your car conversations, together',
            message:
                'Chat with your community and keep marketplace enquiries in one place.',
            icon: Icons.forum_outlined,
          ),
          InfoNote(
            'New conversations start as requests. The recipient chooses whether to accept.',
          ),
          GradientButton(
            label: 'Sign in to message',
            onPressed: () => pushPage<void>(context, AuthPage()),
          ),
        ],
      );
    }
    return _Inbox(
      key: ValueKey(backend!.account!.id),
      api: backend.social!,
      owner: backend.account!.id,
    );
  }
}

class _Inbox extends StatefulWidget {
  const _Inbox({super.key, required this.api, required this.owner});
  final SocialRepository api;
  final String owner;
  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  final List<Conversation> _rows = [];
  Map<String, String> _names = {};
  int _tab = 0;
  bool _busy = false, _more = true;
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
      final rows = await widget.api.inbox(offset: more ? _rows.length : 0);
      final names = await widget.api.names(
        rows.map((c) => c.other(widget.owner)).toList(),
      );
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final rows = _rows
        .where(
          (c) => _tab == 2
              ? c.status != 'active'
              : c.status == 'active' &&
                    (_tab == 1 ? c.listingId != null : c.listingId == null),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Find car lovers',
                onPressed: () => pushPage<void>(context, PeoplePage()),
                icon: Icon(Icons.person_add_alt),
              ),
              IconButton(
                tooltip: 'Refresh messages',
                onPressed: _busy ? null : () => _load(),
                icon: Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in [
                (0, 'Community'),
                (1, 'Marketplace'),
                (2, 'Requests'),
              ])
                Padding(
                  padding: EdgeInsets.all(4),
                  child: ChoiceChip(
                    label: Text(entry.$2),
                    selected: _tab == entry.$1,
                    onSelected: (_) => setState(() => _tab = entry.$1),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: InfoNote(_error!),
          ),
        if (_busy) LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rows.length + 1,
            itemBuilder: (context, index) {
              if (index == rows.length)
                return Column(
                  children: [
                    if (rows.isEmpty && !_busy && _error == null)
                      EmptyState(
                        title: 'No conversations here yet',
                        message:
                            'Find people to follow and send a conversation request.',
                        icon: Icons.chat_bubble_outline,
                      ),
                    if (_more && _rows.isNotEmpty)
                      TextButton(
                        onPressed: _busy ? null : () => _load(more: true),
                        child: Text('Load more conversations'),
                      ),
                  ],
                );
              final c = rows[index];
              final name = _names[c.other(widget.owner)] ?? 'Car enthusiast';
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    c.listingId == null
                        ? Icons.person_outline
                        : Icons.directions_car_outlined,
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  c.status == 'active'
                      ? 'Open conversation'
                      : c.status == 'declined'
                      ? 'Request declined'
                      : c.recipient == widget.owner
                      ? 'Wants to connect'
                      : 'Request sent',
                ),
                trailing: Icon(Icons.chevron_right),
                onTap: () async {
                  await pushPage<void>(
                    context,
                    ConversationPage(
                      conversation: c,
                      name: name,
                      owner: widget.owner,
                    ),
                  );
                  if (mounted) _load();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});
  @override
  Widget build(BuildContext context) {
    final backend = BackendScope.of(context);
    if (backend?.account == null || backend?.social == null)
      return AuthPage();
    return _People(
      key: ValueKey(backend!.account!.id),
      api: backend.social!,
      name: backend.account!.displayName,
    );
  }
}

class _People extends StatefulWidget {
  const _People({super.key, required this.api, required this.name});
  final SocialRepository api;
  final String name;
  @override
  State<_People> createState() => _PeopleState();
}

class _PeopleState extends State<_People> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  Set<String> _following = {};
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.ensureProfile(widget.name);
      final rows = await widget.api.people(_query.text);
      final follows = await widget.api.followingIds(
        rows.map((r) => r['id'] as String).toList(),
      );
      if (mounted)
        setState(() {
          _rows = rows;
          _following = follows;
        });
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Find car lovers',
    children: [
      TextField(
        controller: _query,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          labelText: 'Search display names',
          suffixIcon: IconButton(
            tooltip: 'Search people',
            onPressed: _busy ? null : _search,
            icon: Icon(Icons.search),
          ),
        ),
      ),
      InfoNote(
        'Follow people you enjoy. A conversation request needs their acceptance before messages can be sent.',
      ),
      if (_error != null) InfoNote(_error!),
      if (_busy) LinearProgressIndicator(),
      for (final row in _rows)
        ListTile(
          title: Text(row['display_name'] as String),
          subtitle: Text(
            _following.contains(row['id']) ? 'Following' : 'Car community',
          ),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: _following.contains(row['id']) ? 'Unfollow' : 'Follow',
                onPressed: _busy
                    ? null
                    : () => _action(() async {
                        final id = row['id'] as String;
                        final value = !_following.contains(id);
                        await widget.api.follow(id, value);
                        if (mounted)
                          setState(() {
                            if (value) {
                              _following.add(id);
                            } else {
                              _following.remove(id);
                            }
                          });
                      }),
                icon: Icon(
                  _following.contains(row['id'])
                      ? Icons.person_remove_outlined
                      : Icons.person_add_alt,
                ),
              ),
              IconButton(
                tooltip: 'Request conversation',
                onPressed: _busy || !_following.contains(row['id'])
                    ? null
                    : () => _action(() async {
                        await widget.api.request(row['id'] as String);
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Request sent. Check Messages → Requests.',
                              ),
                            ),
                          );
                      }),
                icon: Icon(Icons.chat_bubble_outline),
              ),
            ],
          ),
        ),
      if (_rows.isEmpty && !_busy && _error == null)
        EmptyState(
          title: 'No people found',
          message:
              'Try a different name. New members appear after opening their community profile.',
        ),
      TextButton(
        onPressed: () => pushPage<void>(context, BlockedPeoplePage()),
        child: Text('Manage blocked people'),
      ),
    ],
  );
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.conversation,
    required this.name,
    required this.owner,
  });
  final Conversation conversation;
  final String name, owner;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _body = TextEditingController();
  final List<ChatMessage> _rows = [];
  late String _status = widget.conversation.status;
  String? _error;
  String _requestId = Uuid().v4();
  bool _busy = false, _loading = false, _more = true;
  SocialRepository get _api => BackendScope.of(context)!.social!;
  bool get _authorized => BackendScope.of(context)?.account?.id == widget.owner;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  bool _started = false;
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading || !_authorized) return;
    final api = _api;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversation = await api.conversation(widget.conversation.id);
      final rows = await api.messages(
        widget.conversation.id,
        offset: more ? _rows.length : 0,
      );
      if (!mounted || !_authorized) return;
      setState(() {
        _status = conversation.status;
        if (!more) _rows.clear();
        final ids = _rows.map((r) => r.id).toSet();
        _rows.addAll(rows.where((r) => !ids.contains(r.id)));
        _more = rows.length == 30;
      });
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(bool accept) async {
    if (_busy || !_authorized) return;
    setState(() => _busy = true);
    try {
      await _api.respond(widget.conversation.id, accept);
      if (mounted) setState(() => _status = accept ? 'active' : 'declined');
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_busy || !_authorized || _body.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.send(widget.conversation.id, _body.text, _requestId);
      if (!mounted || !_authorized) return;
      _body.clear();
      _requestId = Uuid().v4();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _safety(bool report) async {
    if (!_authorized) return;
    final api = _api;
    final other = widget.conversation.other(widget.owner);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          report ? 'Report this conversation?' : 'Block this person?',
        ),
        content: Text(
          report
              ? 'Send a report for review. This does not automatically block the person.'
              : 'Messages in both directions will stop. You can unblock them from Find car lovers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(report ? 'Report' : 'Block'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || !_authorized) return;
    try {
      if (report) {
        await api.report(
          other,
          'Conversation reported: ${widget.conversation.id}',
        );
      } else {
        await api.block(other, name: widget.name);
      }
      if (!mounted) return;
      if (report) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report submitted.')));
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authorized)
      return PageFrame(
        title: 'Messages',
        children: [
          InfoNote('Your session changed. Return to Messages to continue.'),
        ],
      );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            tooltip: 'Refresh conversation',
            onPressed: _loading ? null : () => _load(),
            icon: Icon(Icons.refresh),
          ),
          PopupMenuButton<bool>(
            onSelected: _safety,
            itemBuilder: (_) => [
              PopupMenuItem(value: true, child: Text('Report')),
              PopupMenuItem(value: false, child: Text('Block')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: InfoNote(_error!),
              ),
            if (_loading) LinearProgressIndicator(),
            if (_status == 'pending')
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.conversation.recipient == widget.owner
                          ? 'Accept this conversation request?'
                          : 'Waiting for acceptance. Messages are disabled until then.',
                    ),
                    if (widget.conversation.recipient == widget.owner)
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: _busy ? null : () => _respond(true),
                            child: Text('Accept'),
                          ),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _respond(false),
                            child: Text('Decline'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (_status == 'declined')
              InfoNote('This conversation request was declined.'),
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.all(16),
                itemCount: _rows.length + 1,
                itemBuilder: (context, index) {
                  if (index == _rows.length)
                    return _more && _rows.isNotEmpty
                        ? TextButton(
                            onPressed: _loading
                                ? null
                                : () => _load(more: true),
                            child: Text('Older messages'),
                          )
                        : SizedBox.shrink();
                  final m = _rows[index];
                  return Align(
                    alignment: m.sender == widget.owner
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 310),
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.sender == widget.owner
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : NightTheme.panel(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(m.body),
                    ),
                  );
                },
              ),
            ),
            if (_status == 'active')
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _body,
                        enabled: !_busy,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        onChanged: (_) => _requestId = Uuid().v4(),
                        decoration: InputDecoration(
                          labelText: 'Message',
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send message',
                      onPressed: _busy ? null : _send,
                      icon: _busy
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BlockedPeoplePage extends StatefulWidget {
  const BlockedPeoplePage({super.key});
  @override
  State<BlockedPeoplePage> createState() => _BlockedPeoplePageState();
}

class _BlockedPeoplePageState extends State<BlockedPeoplePage> {
  List<Map<String, dynamic>> _rows = [];
  String? _error;
  bool _busy = false;
  String? _owner;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = BackendScope.of(context)?.account?.id;
    if (_owner != id) {
      _owner = id;
      _rows = [];
      if (id != null) _load();
    }
  }

  Future<void> _load() async {
    if (_busy) return;
    final backend = BackendScope.of(context);
    final requestedOwner = _owner;
    if (backend?.social == null) return;
    setState(() => _busy = true);
    try {
      final rows = await backend!.social!.blocked();
      if (mounted && _owner == requestedOwner) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = serviceError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Blocked people',
    children: [
      if (_error != null) InfoNote(_error!),
      if (_busy) LinearProgressIndicator(),
      for (final row in _rows)
        ListTile(
          title: Text(row['blocked_label'] as String? ?? 'Car enthusiast'),
          trailing: TextButton(
            onPressed: _busy
                ? null
                : () async {
                    final api = BackendScope.of(context)?.social;
                    if (api == null) return;
                    try {
                      await api.unblock(row['blocked_id'] as String);
                      if (mounted) await _load();
                    } catch (e) {
                      if (mounted) setState(() => _error = serviceError(e));
                    }
                  },
            child: Text('Unblock'),
          ),
        ),
      if (_rows.isEmpty && !_busy) InfoNote('No blocked people.'),
    ],
  );
}
