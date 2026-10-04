import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Home-only presentation: author, expandable caption, uncropped media,
/// engagement summary and separate labelled actions.
class HomePost extends StatelessWidget {
  const HomePost({
    super.key,
    required this.id,
    required this.author,
    required this.subtitle,
    required this.caption,
    required this.media,
    required this.likes,
    required this.comments,
    required this.liked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.trailing,
    this.saved = false,
    this.onSave,
  });
  final String id, author, subtitle, caption;
  final Widget media;
  final int likes, comments;
  final bool liked, saved;
  final VoidCallback? onLike, onComment, onShare, onSave;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: NightTheme.panel(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(author.isEmpty ? 'C' : author.characters.first),
          ),
          title: Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: NightTheme.secondaryText(context), fontSize: 11),
          ),
          trailing: trailing,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: _Caption(caption),
        ),
        media,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.favorite, color: Theme.of(context).colorScheme.secondary, size: 15),
              SizedBox(width: 6),
              Text(
                '$likes',
                style: TextStyle(color: NightTheme.secondaryText(context), fontSize: 12),
              ),
              Spacer(),
              Text(
                '$comments comments',
                style: TextStyle(color: NightTheme.secondaryText(context), fontSize: 12),
              ),
              if (onSave != null)
                IconButton(
                  key: ValueKey('save-$id'),
                  tooltip: saved ? 'Unsave post' : 'Save post',
                  onPressed: onSave,
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    size: 21,
                  ),
                ),
              if (onSave == null) SizedBox(height: 42),
            ],
          ),
        ),
        Divider(height: 1, indent: 14, endIndent: 14),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: ValueKey('like-$id'),
                onPressed: onLike,
                style: TextButton.styleFrom(
                  foregroundColor: liked
                      ? Theme.of(context).colorScheme.secondary
                      : NightTheme.secondaryText(context),
                ),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                ),
                label: Text('Like', style: TextStyle(fontSize: 11)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onComment,
                style: TextButton.styleFrom(foregroundColor: NightTheme.secondaryText(context)),
                icon: Icon(Icons.chat_bubble_outline, size: 19),
                label: Text('Comment', style: TextStyle(fontSize: 11)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onShare,
                style: TextButton.styleFrom(foregroundColor: NightTheme.secondaryText(context)),
                icon: Icon(Icons.share_outlined, size: 20),
                label: Text('Share', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Caption extends StatefulWidget {
  const _Caption(this.text);
  final String text;
  @override
  State<_Caption> createState() => _CaptionState();
}

class _CaptionState extends State<_Caption> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.text,
        maxLines: expanded || widget.text.length <= 85 ? null : 2,
        overflow: expanded || widget.text.length <= 85
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
      ),
      if (widget.text.length > 85 || widget.text.contains('\n'))
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              expanded ? 'Show less' : 'See more',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
            ),
          ),
        ),
    ],
  );
}
