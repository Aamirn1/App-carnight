import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cars_night/backend/config.dart';
import 'package:cars_night/backend/repositories.dart';
import 'package:cars_night/backend/session.dart';
import 'package:cars_night/backend/supabase_repositories.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/auth.dart';
import 'package:cars_night/ui/account.dart';

const owner = '11111111-1111-1111-1111-111111111111';
String jwt(Map<String, dynamic> payload) =>
    '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode(payload)))}.signature';
Map<String, dynamic> sessionJson() => {
  'access_token': jwt({
    'sub': owner,
    'role': 'authenticated',
    'exp': 4102444800,
  }),
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': owner,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'driver@example.com',
    'created_at': '2026-10-01T00:00:00Z',
    'app_metadata': <String, dynamic>{},
    'user_metadata': {'display_name': 'Driver'},
  },
};

class FakeAccounts implements AccountsRepository {
  final changes = StreamController<AccountSummary?>.broadcast(sync: true);
  final recovery = StreamController<bool>.broadcast(sync: true);
  final restored = Completer<AccountSummary?>();
  Completer<void>? signInResult;
  int attempts = 0;
  Future<void> dispose() async {
    await changes.close();
    await recovery.close();
  }

  @override
  Stream<AccountSummary?> get accountChanges => changes.stream;
  @override
  Stream<bool> get recoveryChanges => recovery.stream;
  @override
  Future<AccountSummary?> currentAccount() => restored.future;
  @override
  Future<void> signIn({required String email, required String password}) async {
    attempts++;
    await signInResult?.future;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {}
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> updatePassword(String password) async {}
  @override
  Future<void> signOut() async {
    changes.add(null);
  }
}

class FakeDrafts implements DraftsRepository {
  @override
  Future<List<ContentDraft>> load(DraftKind kind, {int offset = 0}) async => [];
  @override
  Future<void> save({
    required DraftKind kind,
    String? id,
    required String text,
    String city = '',
    String currency = 'USD',
    int? priceMinor,
  }) async {}
  @override
  Future<void> delete(ContentDraft draft) async {}
}

void main() {
  test(
    'client configuration rejects placeholders and privileged credentials',
    () {
      const url = 'https://example.supabase.co';
      for (final key in [
        '',
        'your-anon-key',
        'sb_secret_private',
        jwt({'role': 'service_role'}),
      ]) {
        expect(BackendConfig(url: url, key: key).validationError, isNotNull);
      }
      expect(
        BackendConfig(url: url, key: jwt({'role': 'anon'})).validationError,
        isNull,
      );
      expect(
        const BackendConfig(
          url: url,
          key: 'sb_publishable_example_public_key',
        ).validationError,
        isNull,
      );
      expect(
        const BackendConfig(
          url: 'http://example.com',
          key: 'sb_publishable_example_public_key',
        ).validationError,
        isNotNull,
      );
    },
  );

  test(
    'price parsing preserves cents and rejects ambiguous or invalid amounts',
    () {
      expect(parseDraftPrice('1234.56'), 123456);
      expect(parseDraftPrice('0.01'), 1);
      expect(parseDraftPrice('12.5'), 1250);
      for (final value in [
        '0',
        '-1',
        'NaN',
        '1,000',
        '1.234',
        '1e8',
        '99999999999999',
      ]) {
        expect(parseDraftPrice(value), isNull);
      }
    },
  );

  test('late session restoration cannot overwrite a newer sign-out', () async {
    final accounts = FakeAccounts();
    final session = BackendSession(accounts: accounts, drafts: FakeDrafts());
    addTearDown(session.dispose);
    accounts.changes.add(null);
    accounts.restored.complete(
      const AccountSummary(id: owner, displayName: 'Stale user'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(session.account, isNull);
    accounts.recovery.add(true);
    expect(session.recovering, isTrue);
    accounts.changes.add(null);
    expect(session.recovering, isFalse);
    await accounts.dispose();
  });

  testWidgets('missing key disables account submission', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: NightTheme.data, home: const AuthPage()),
    );
    expect(
      find.textContaining('Online accounts are not enabled'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('sign-in prevents duplicate requests and recovers from failure', (
    tester,
  ) async {
    final accounts = FakeAccounts()..signInResult = Completer<void>();
    accounts.restored.complete(null);
    final session = BackendSession(accounts: accounts, drafts: FakeDrafts());
    addTearDown(session.dispose);
    await tester.pumpWidget(
      BackendScope(
        session: session,
        child: MaterialApp(theme: NightTheme.data, home: const AuthPage()),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'driver@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(accounts.attempts, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    accounts.signInResult!.completeError(
      const AuthException('Invalid', code: 'invalid_credentials'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await accounts.dispose();
  });

  test(
    'Supabase adapter scopes pages and mutations to the signed-in draft owner',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/auth/v1/token')
            return http.Response(
              jsonEncode(sessionJson()),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          if (request.method == 'GET')
            return http.Response(
              '[]',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          return http.Response('', 201, request: request);
        }),
      );
      addTearDown(client.dispose);
      final accounts = SupabaseAccountsRepository(client);
      await accounts.signIn(
        email: ' driver@example.com ',
        password: 'password123',
      );
      expect(jsonDecode(requests.first.body)['email'], 'driver@example.com');
      expect((await accounts.currentAccount())!.displayName, 'Driver');
      final drafts = SupabaseDraftsRepository(client);
      await drafts.load(DraftKind.sale, offset: 20);
      final query = requests.last.url.queryParameters;
      expect(requests.last.url.path, '/rest/v1/cn_listings');
      expect(query['owner_id'], 'eq.$owner');
      expect(query['status'], 'eq.draft');
      expect(query['kind'], 'eq.sale');
      expect(query['offset'], '20');
      expect(query['limit'], '20');
      await drafts.save(kind: DraftKind.post, text: '  My draft  ');
      final body = jsonDecode(requests.last.body);
      expect(body['owner_id'], owner);
      expect(body['status'], 'draft');
      expect(body['caption'], 'My draft');
    },
  );

  test('anonymous draft writes fail before any network request', () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async {
        requests++;
        return http.Response('[]', 200);
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseDraftsRepository(
        client,
      ).save(kind: DraftKind.post, text: 'Draft'),
      throwsA(isA<AuthException>()),
    );
    expect(requests, 0);
  });
}
