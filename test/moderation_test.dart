import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/ui/moderation.dart';

class ReviewApi implements SocialRepository {
  bool fail = false;
  final decisions = <String>[];
  @override
  Future<List<Map<String, dynamic>>> moderationQueue() async {
    if (fail) throw Exception('denied');
    if (decisions.isNotEmpty) return [];
    return [{'id': 'report-1', 'reason': 'Spam or scam', 'caption': 'Reported caption', 'target_post_id': 'post-1', 'images': <String>[]}];
  }
  @override
  Future<void> reviewReport(String id, String decision, String note) async {
    decisions.add('$id:$decision:$note');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('removal requires a review note and confirmation', (tester) async {
    final api = ReviewApi();
    await tester.pumpWidget(MaterialApp(home: ModerationPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove post'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove post').last);
    await tester.pumpAndSettle();
    expect(api.decisions, isEmpty);
    await tester.enterText(find.byType(TextField), 'Confirmed scam');
    await tester.tap(find.widgetWithText(TextButton, 'Remove post').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.decisions, ['report-1:removed:Confirmed scam']);
    expect(find.text('No reports awaiting review.'), findsOneWidget);
  });
  testWidgets('cancel does not remove content', (tester) async {
    final api = ReviewApi();
    await tester.pumpWidget(MaterialApp(home: ModerationPage(api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(api.decisions, isEmpty);
  });
}
