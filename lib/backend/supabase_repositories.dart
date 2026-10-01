import 'package:supabase_flutter/supabase_flutter.dart';
import 'repositories.dart';

const authCallback = 'com.carsnight.preview://auth-callback/';

class SupabaseAccountsRepository implements AccountsRepository {
  SupabaseAccountsRepository(this.client);
  final SupabaseClient client;

  AccountSummary? _account(User? user) => user == null
      ? null
      : AccountSummary(
          id: user.id,
          displayName:
              (user.userMetadata?['display_name'] as String?) ??
              'Car enthusiast',
        );

  @override
  Stream<AccountSummary?> get accountChanges => client.auth.onAuthStateChange
      .map((event) => _account(event.session?.user));
  @override
  Stream<bool> get recoveryChanges => client.auth.onAuthStateChange
      .where(
        (event) =>
            event.event == AuthChangeEvent.passwordRecovery ||
            event.event == AuthChangeEvent.signedOut,
      )
      .map((event) => event.event == AuthChangeEvent.passwordRecovery);
  @override
  Future<AccountSummary?> currentAccount() async =>
      _account(client.auth.currentUser);
  @override
  Future<void> signIn({required String email, required String password}) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
      emailRedirectTo: authCallback,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      client.auth.resetPasswordForEmail(email.trim(), redirectTo: authCallback);
  @override
  Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}

class SupabaseDraftsRepository implements DraftsRepository {
  SupabaseDraftsRepository(this.client);
  final SupabaseClient client;
  String get _owner =>
      client.auth.currentUser?.id ??
      (throw const AuthException('Sign in to manage drafts.'));
  String _table(DraftKind kind) =>
      kind == DraftKind.post ? 'cn_posts' : 'cn_listings';

  @override
  Future<List<ContentDraft>> load(DraftKind kind, {int offset = 0}) async {
    if (offset < 0) throw ArgumentError('Invalid page.');
    var query = client
        .from(_table(kind))
        .select()
        .eq('owner_id', _owner)
        .eq('status', 'draft');
    if (kind != DraftKind.post) query = query.eq('kind', kind.name);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 19);
    return rows
        .map(
          (row) => ContentDraft(
            id: row['id'] as String,
            kind: kind,
            text: row[kind == DraftKind.post ? 'caption' : 'title'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
            city: row['city'] as String? ?? '',
            currency: row['currency'] as String? ?? 'USD',
            priceMinor: (row['price_minor'] as num?)?.toInt(),
          ),
        )
        .toList();
  }

  @override
  Future<void> save({
    required DraftKind kind,
    String? id,
    required String text,
    String city = '',
    String currency = 'USD',
    int? priceMinor,
  }) async {
    final owner = _owner;
    final cleaned = text.trim();
    if (cleaned.isEmpty ||
        cleaned.length > (kind == DraftKind.post ? 500 : 80)) {
      throw ArgumentError('Enter a valid caption or title.');
    }
    if (kind != DraftKind.post &&
        (city.trim().isEmpty ||
            city.trim().length > 80 ||
            !RegExp(r'^[A-Z]{3}$').hasMatch(currency) ||
            priceMinor == null ||
            priceMinor <= 0)) {
      throw ArgumentError('Enter a city, currency and positive price.');
    }
    final values = <String, dynamic>{
      if (kind == DraftKind.post)
        'caption': cleaned
      else ...{
        'kind': kind.name,
        'title': cleaned,
        'city': city.trim(),
        'currency': currency,
        'price_minor': priceMinor,
      },
    };
    if (id == null) {
      await client.from(_table(kind)).insert({
        ...values,
        'owner_id': owner,
        'status': 'draft',
      });
    } else {
      // single() reports missing/stale/non-owned drafts instead of false success.
      await client
          .from(_table(kind))
          .update(values)
          .eq('id', id)
          .eq('owner_id', owner)
          .eq('status', 'draft')
          .select('id')
          .single();
    }
  }

  @override
  Future<void> delete(ContentDraft draft) async {
    await client
        .from(_table(draft.kind))
        .delete()
        .eq('id', draft.id)
        .eq('owner_id', _owner)
        .eq('status', 'draft')
        .select('id')
        .single();
  }
}

String serviceError(Object error) {
  if (error is AuthException) {
    if (error.code == 'invalid_credentials')
      return 'Email or password is incorrect.';
    if (error.code == 'email_not_confirmed')
      return 'Confirm your email before signing in.';
    if (error.statusCode == '429')
      return 'Too many attempts. Please try again later.';
    return 'The account request failed. Check your details and connection, then retry.';
  }
  if (error is PostgrestException) {
    if (error.code == '42P01' || error.code == 'PGRST205') {
      return 'Online drafts are not enabled on the server yet.';
    }
    return 'Could not save or load this draft. Refresh and try again.';
  }
  return 'Could not connect. Check your internet connection and try again.';
}
