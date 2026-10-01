import 'package:flutter/foundation.dart';
import '../data/demo_catalog.dart';
import '../domain/models.dart';
import 'assets.dart';

/// All changes are local to the demo session. This is not persistence or auth.
class DemoSession extends ChangeNotifier {
  final Set<String> _saved = {};
  final Set<String> _liked = {};
  final List<SocialPost> _posts = List.of(DemoCatalog.posts);
  final Map<String, List<String>> _comments = {};
  int _nextPost = 0;
  bool _dataSaver = false;

  bool get dataSaver => _dataSaver;
  List<SocialPost> get posts => List.unmodifiable(_posts);
  bool isSaved(String id) => _saved.contains(id);
  bool isLiked(String id) => _liked.contains(id);
  int get savedCount => _saved.length;
  List<String> commentsFor(String id) => List.unmodifiable(_comments[id] ?? []);

  void setDataSaver(bool value) {
    if (_dataSaver == value) return;
    _dataSaver = value;
    notifyListeners();
  }

  void toggleSaved(String id) {
    if (!_saved.remove(id)) _saved.add(id);
    notifyListeners();
  }

  void toggleLiked(String id) {
    if (!_liked.remove(id)) _liked.add(id);
    notifyListeners();
  }

  SocialPost addDemoPost(String caption, List<String> imageAssets) {
    final text = caption.trim();
    if (text.isEmpty || text.length > 500) {
      throw ArgumentError('Caption must have 1–500 characters.');
    }
    if (imageAssets.isEmpty ||
        imageAssets.length > UploadPolicy.maxImages ||
        imageAssets.any((asset) => !NightAssets.photos.contains(asset))) {
      throw ArgumentError('Choose 1–4 bundled sample images.');
    }
    final post = SocialPost(
        id: 'local-${++_nextPost}',
        author: 'You',
        city: 'Local demo',
        caption: text,
        imageAssets: List.unmodifiable(imageAssets));
    _posts.insert(0, post);
    notifyListeners();
    return post;
  }

  void addComment(String postId, String comment) {
    final text = comment.trim();
    if (!_posts.any((p) => p.id == postId) ||
        text.isEmpty ||
        text.length > 500) {
      throw ArgumentError(
          'Comment requires an existing post and 1–500 characters.');
    }
    (_comments[postId] ??= []).add(text);
    notifyListeners();
  }

  void removeDemoPost(String id) {
    if (!id.startsWith('local-'))
      throw ArgumentError('Only your demo posts can be deleted.');
    _posts.removeWhere((post) => post.id == id);
    _saved.remove(id);
    _liked.remove(id);
    _comments.remove(id);
    notifyListeners();
  }
}
