/// Provider-independent boundaries for the connected-services milestone.
/// No implementation here authenticates users or publishes demo content.
class AccountSummary {
  const AccountSummary({required this.id, required this.displayName});
  final String id;
  final String displayName;
}

class PageSlice<T> {
  PageSlice({required List<T> items, this.nextCursor})
      : items = List.unmodifiable(items);
  final List<T> items;
  final String? nextCursor;
}

abstract interface class AccountsRepository {
  Stream<AccountSummary?> get accountChanges;
  Future<AccountSummary?> currentAccount();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password,
    required String displayName});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class PostSummary {
  const PostSummary({required this.id, required this.ownerId,
    required this.caption, required this.createdAt});
  final String id;
  final String ownerId;
  final String caption;
  final DateTime createdAt;
}

abstract interface class PostsRepository {
  Future<PageSlice<PostSummary>> publishedFeed({String? cursor, int limit = 20});
  Future<PostSummary> createDraft(String caption);
  Future<void> deleteOwnPost(String id);
}

/// Actual upload support must decode/re-encode bytes and verify media on the
/// server. These contracts deliberately do not expose a client approve method.
abstract interface class ImageUploadsRepository {
  Future<Uri> requestUpload({required String fileName, required String mimeType,
    required int byteLength});
  Future<void> requestValidation(String uploadId);
}
