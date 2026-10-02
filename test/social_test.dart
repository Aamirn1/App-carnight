import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cars_night/backend/repositories.dart';
import 'package:cars_night/backend/session.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/messages.dart';
import 'backend_test.dart' as fixtures;

const other = '22222222-2222-2222-2222-222222222222';
Conversation conversation({String status = 'active'}) => Conversation.fromJson({
  'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'requester_id': fixtures.owner,
  'recipient_id': other,
  'status': status,
  'listing_id': null,
});

class FakeSocial implements SocialRepository {
  @override
  Future<void> ensureProfile(String name) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
  final requestIds = <String>[];
  bool failSend = true;
  @override
  Future<Conversation> conversation(String id) async => Conversation.fromJson({
    'id': id,
    'requester_id': fixtures.owner,
    'recipient_id': other,
    'status': 'active',
    'listing_id': null,
  });
  @override
  Future<List<ChatMessage>> messages(
    String conversation, {
    int offset = 0,
  }) async => [
    ChatMessage.fromJson({
      'id': 'm1',
      'sender_id': other,
      'body': 'Private conversation text',
      'created_at': '2026-10-02T00:00:00Z',
    }),
  ];
  @override
  Future<void> send(String conversation, String body, String requestId) async {
    requestIds.add(requestId);
    if (failSend) throw const AuthException('Network problem');
  }
}

void main() {
  testWidgets('Messages invites guests to sign in without fake conversations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NightTheme.data,
        home: const Scaffold(body: MessagesPage()),
      ),
    );
    expect(find.text('Sign in to message'), findsOneWidget);
    expect(find.textContaining('recipient chooses'), findsOneWidget);
    expect(find.text('Online'), findsNothing);
  });
  testWidgets(
    'message retry preserves its request ID and sign-out hides history',
    (tester) async {
      final api = FakeSocial();
      final accounts = fixtures.FakeAccounts();
      accounts.restored.complete(
        const AccountSummary(id: fixtures.owner, displayName: 'Driver'),
      );
      final backend = BackendSession(
        accounts: accounts,
        drafts: fixtures.FakeDrafts(),
        social: api,
      );
      addTearDown(backend.dispose);
      await tester.pumpWidget(
        BackendScope(
          session: backend,
          child: MaterialApp(
            theme: NightTheme.data,
            home: ConversationPage(
              conversation: conversation(),
              name: 'Other driver',
              owner: fixtures.owner,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Restoration may occur after the route's first dependency update. Refresh is recoverable.
      await tester.tap(find.byTooltip('Refresh conversation'));
      await tester.pumpAndSettle();
      expect(find.text('Private conversation text'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.requestIds.length, 1);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.requestIds.length, 2);
      expect(api.requestIds[0], api.requestIds[1]);
      accounts.changes.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Private conversation text'), findsNothing);
      expect(find.textContaining('Your session changed'), findsOneWidget);
      await accounts.dispose();
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
  test(
    'feed adapter sends a stable cursor and message adapter reuses the retry token',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          return http.Response(
            r.url.path.endsWith('cn_feed') ? '[]' : '"message-id"',
            200,
            request: r,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final api = SocialRepository(client);
      final cursor = CommunityPost.fromJson({
        'id': 'post-id',
        'owner_id': other,
        'caption': 'Photo',
        'display_name': 'Driver',
        'created_at': '2026-10-02T00:00:00Z',
        'like_count': 0,
        'comment_count': 0,
        'liked': false,
        'following': false,
        'images': <String>[],
      });
      await api.feed(following: true, before: cursor);
      expect(jsonDecode(requests.last.body), {
        'following_only': true,
        'before_time': cursor.createdAt,
        'before_id': 'post-id',
      });
      await api.send('conversation-id', ' Hello ', 'retry-id');
      expect(jsonDecode(requests.last.body), {
        'conversation': 'conversation-id',
        'message_body': 'Hello',
        'request_id': 'retry-id',
      });
      await api.send('conversation-id', ' Hello ', 'retry-id');
      expect(jsonDecode(requests.last.body)['request_id'], 'retry-id');
    },
  );
}
