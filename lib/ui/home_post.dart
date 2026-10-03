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
    color: NightTheme.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF352650),
            child: Text(author.isEmpty ? 'C' : author.characters.first),
          ),
          title: Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: NightTheme.muted, fontSize: 11),
          ),
          trailing: trailing,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: _Caption(caption),
        ),
        media,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: NightTheme.magenta, size: 15),
              const SizedBox(width: 6),
              Text(
                '$likes',
                style: const TextStyle(color: NightTheme.muted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$comments comments',
                style: const TextStyle(color: NightTheme.muted, fontSize: 12),
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
              if (onSave == null) const SizedBox(height: 42),
            ],
          ),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                key: ValueKey('like-$id'),
                onPressed: onLike,
                style: TextButton.styleFrom(
                  foregroundColor: liked
                      ? NightTheme.magenta
                      : NightTheme.muted,
                ),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                ),
                label: const Text('Like', style: TextStyle(fontSize: 11)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onComment,
                style: TextButton.styleFrom(foregroundColor: NightTheme.muted),
                icon: const Icon(Icons.chat_bubble_outline, size: 19),
                label: const Text('Comment', style: TextStyle(fontSize: 11)),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onShare,
                style: TextButton.styleFrom(foregroundColor: NightTheme.muted),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text('Share', style: TextStyle(fontSize: 11)),
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
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              expanded ? 'Show less' : 'See more',
              style: const TextStyle(color: NightTheme.cyan, fontSize: 12),
            ),
          ),
        ),
    ],
  );
}
