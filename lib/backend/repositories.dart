/// Provider-independent boundaries for the connected-services milestone.
/// No implementation here authenticates users or publishes demo content.
class AccountSummary {
  const AccountSummary({
    required this.id,
    required this.displayName,
    this.countryCode = '',
    this.city = '',
  });
  final String id;
  final String displayName;
  final String countryCode, city;
}

class PageSlice<T> {
  PageSlice({required List<T> items, this.nextCursor})
    : items = List.unmodifiable(items);
  final List<T> items;
  final String? nextCursor;
}

abstract interface class AccountsRepository {
  Stream<AccountSummary?> get accountChanges;
  Stream<bool> get recoveryChanges;
  Future<AccountSummary?> currentAccount();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String countryCode = '',
    String city = '',
  });
  Future<void> verifyEmailCode({required String email, required String code});
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}

enum DraftKind { post, sale, rental }

class ContentDraft {
  const ContentDraft({
    required this.id,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.city = '',
    this.currency = 'USD',
    this.priceMinor,
  });
  final String id;
  final DraftKind kind;
  final String text;
  final DateTime createdAt;
  final String city;
  final String currency;
  final int? priceMinor;
}

abstract interface class DraftsRepository {
  Future<List<ContentDraft>> load(DraftKind kind, {int offset = 0});
  Future<void> save({
    required DraftKind kind,
    String? id,
    required String text,
    String city = '',
    String currency = 'USD',
    int? priceMinor,
  });
  Future<void> delete(ContentDraft draft);
}

class PostSummary {
  const PostSummary({
    required this.id,
    required this.ownerId,
    required this.caption,
    required this.createdAt,
  });
  final String id;
  final String ownerId;
  final String caption;
  final DateTime createdAt;
}

abstract interface class PostsRepository {
  Future<PageSlice<PostSummary>> publishedFeed({
    String? cursor,
    int limit = 20,
  });
  Future<PostSummary> createDraft(String caption);
  Future<void> deleteOwnPost(String id);
}

/// Actual upload support must decode/re-encode bytes and verify media on the
/// server. These contracts deliberately do not expose a client approve method.
abstract interface class ImageUploadsRepository {
  Future<Uri> requestUpload({
    required String fileName,
    required String mimeType,
    required int byteLength,
  });
  Future<void> requestValidation(String uploadId);
}
