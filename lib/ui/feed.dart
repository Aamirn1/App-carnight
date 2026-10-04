import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/assets.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../domain/models.dart';
import 'components.dart';
import 'home_post.dart';
import '../core/platform_actions.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({
    super.key,
    required this.session,
    this.query = '',
    this.homeLayout = false,
    this.header,
  });
  final DemoSession session;
  final String query;
  final bool homeLayout;
  final Widget? header;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final posts = session.posts
          .where(
            (post) => '${post.author} ${post.caption} ${post.city}'
                .toLowerCase()
                .contains(query.trim().toLowerCase()),
          )
          .toList();
      if (posts.isEmpty) {
        return ListView(
          children: [
            if (header != null) header!,
            EmptyState(
              title: 'No posts found',
              message: 'Try a different person, city or keyword.',
            ),
          ],
        );
      }
      return ListView.builder(
        key: PageStorageKey<String>('feed'),
        padding: EdgeInsets.symmetric(horizontal: homeLayout ? 0 : 16),
        itemCount: posts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0)
            return header ??
                (query.isEmpty
                    ? StoryRail()
                    : SizedBox(height: 12));
          return Padding(
            padding: EdgeInsets.only(bottom: homeLayout ? 8 : 18),
            child: PostCard(
              post: posts[index - 1],
              session: session,
              homeLayout: homeLayout,
            ),
          );
        },
      );
    },
  );
}

class StoryRail extends StatelessWidget {
  const StoryRail();
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 2, 0, 4),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            [
                  ('Night drives', NightAssets.hero),
                  ('Supercars', NightAssets.violet),
                  ('Open roads', NightAssets.red),
                  ('Adventure', NightAssets.suv),
                ]
                .map(
                  (story) => Padding(
                    padding: EdgeInsetsDirectional.only(end: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => pushPage<void>(
                        context,
                        PageFrame(
                          title: story.$1,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: AssetPhoto(asset: story.$2, ratio: 0.8),
                            ),
                            InfoNote(
                              'Sample photo story. No video or automatic playback.',
                            ),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: NightTheme.gradient,
                              ),
                              child: ClipOval(
                                child: AssetPhoto(asset: story.$2, ratio: 1),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              story.$1,
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    ),
  );
}

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.session,
    this.openOnComment = true,
    this.homeLayout = false,
  });
  final SocialPost post;
  final DemoSession session;
  final bool openOnComment;
  final bool homeLayout;
  @override
  Widget build(BuildContext context) => homeLayout
      ? HomePost(
          key: ValueKey(post.id),
          id: post.id,
          author: post.author,
          subtitle: '${post.city} · Demo',
          caption: post.caption,
          likes: session.isLiked(post.id) ? 1 : 0,
          comments: session.commentsFor(post.id).length,
          liked: session.isLiked(post.id),
          saved: session.isSaved(post.id),
          onLike: () => session.toggleLiked(post.id),
          onSave: () => session.toggleSaved(post.id),
          onComment: () =>
              pushPage<void>(context, PostDetail(post: post, session: session)),
          onShare: () async {
            if (!await PlatformActions.shareText(
              'Cars Night · ${post.author}\n${post.caption}',
            )) {
              await Clipboard.setData(ClipboardData(text: post.caption));
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Caption copied.')),
                );
            }
          },
          trailing: IconButton(
            tooltip: 'Post options',
            icon: Icon(Icons.more_horiz),
            onPressed: () => pushPage<void>(
              context,
              PostDetail(post: post, session: session),
            ),
          ),
          media: AspectRatio(
            aspectRatio: 4 / 5,
            child: PageView(
              children: [
                for (final asset in post.imageAssets)
                  Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    cacheWidth: session.dataSaver ? 480 : 1000,
                    semanticLabel: 'Full photo by ${post.author}',
                  ),
              ],
            ),
          ),
        )
      : NightCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF352650),
                  child: Text(
                    post.author[0],
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  post.author,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${post.city} · Demo',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Post options',
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('Delete demo post?'),
                          content: Text(
                            'This removes it from this local session.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        session.removeDemoPost(post.id);
                        if (!openOnComment && context.mounted)
                          Navigator.pop(context);
                      }
                    } else {
                      await showUnavailable(
                        context,
                        'Report post',
                        'Moderation will be connected before real posts are accepted. '
                            'No report has been sent.',
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report post'),
                    ),
                    if (post.id.startsWith('local-'))
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete demo post'),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(post.caption),
              ),
              if (post.imageAssets.length == 1)
                AssetPhoto(
                  asset: post.imageAssets.first,
                  dataSaver: session.dataSaver,
                )
              else
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    itemCount: post.imageAssets.length,
                    itemBuilder: (_, index) => AssetPhoto(
                      asset: post.imageAssets[index],
                      dataSaver: session.dataSaver,
                      label: 'Photo ${index + 1} of ${post.imageAssets.length}',
                    ),
                  ),
                ),
              if (post.imageAssets.length > 1)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    '${post.imageAssets.length} photos · swipe to view',
                    style: TextStyle(
                      color: NightTheme.secondaryText(context),
                      fontSize: 11,
                    ),
                  ),
                ),
              ListenableBuilder(
                listenable: session,
                builder: (context, _) => Row(
                  children: [
                    IconButton(
                      key: ValueKey('like-${post.id}'),
                      tooltip: session.isLiked(post.id)
                          ? 'Unlike post'
                          : 'Like post',
                      onPressed: () => session.toggleLiked(post.id),
                      icon: Icon(
                        session.isLiked(post.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Text(session.isLiked(post.id) ? '1' : '0'),
                    IconButton(
                      tooltip: 'Comments',
                      onPressed: openOnComment
                          ? () => pushPage<void>(
                              context,
                              PostDetail(post: post, session: session),
                            )
                          : null,
                      icon: Icon(Icons.chat_bubble_outline, size: 20),
                    ),
                    Text('${session.commentsFor(post.id).length}'),
                    IconButton(
                      tooltip: 'Copy caption',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: post.caption),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Caption copied.')),
                        );
                      },
                      icon: Icon(Icons.copy_outlined, size: 20),
                    ),
                    Spacer(),
                    IconButton(
                      key: ValueKey('save-${post.id}'),
                      tooltip: session.isSaved(post.id)
                          ? 'Unsave post'
                          : 'Save post',
                      onPressed: () => session.toggleSaved(post.id),
                      icon: Icon(
                        session.isSaved(post.id)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
}

class PostDetail extends StatefulWidget {
  const PostDetail({super.key, required this.post, required this.session});
  final SocialPost post;
  final DemoSession session;
  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  final _comment = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) => PageFrame(
      title: 'Post',
      children: [
        PostCard(
          post: widget.post,
          session: widget.session,
          openOnComment: false,
        ),
        SizedBox(height: 20),
        Text('Comments', style: Theme.of(context).textTheme.titleLarge),
        if (widget.session.commentsFor(widget.post.id).isEmpty)
          InfoNote(
            'Start the conversation. Demo comments stay on this device until you exit.',
          ),
        for (final comment in widget.session.commentsFor(widget.post.id))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('Y')),
            title: Text('You · Demo'),
            subtitle: Text(comment),
          ),
        SizedBox(height: 12),
        Form(
          key: _form,
          child: TextFormField(
            controller: _comment,
            maxLength: 500,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Write a comment'),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Write a comment first.' : null,
          ),
        ),
        GradientButton(
          label: 'Add demo comment',
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            widget.session.addComment(widget.post.id, _comment.text);
            _comment.clear();
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    ),
  );
}

class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({super.key, required this.session});
  final DemoSession session;
  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Search community')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'People, places or captions',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: FeedPage(session: widget.session, query: _query),
          ),
        ],
      ),
    ),
  );
}
