import 'package:cars_night/backend/session.dart';
import 'package:cars_night/backend/repositories.dart';
import 'package:cars_night/ui/listing_edit.dart';
import 'backend_test.dart' as fixtures;
import 'package:flutter/material.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/ui/live_market.dart';
import 'package:cars_night/core/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/backend/market.dart';

class FakeMarket implements SocialRepository {
 final requests = <Map<String,dynamic>>[];
 Map<String,dynamic>? edited;
 @override Future<void> editListing(Map<String,dynamic> row) async { edited=row; throw StateError('conflict'); }
 @override
 Future<List<Map<String,dynamic>>> market({required String kind,String country='',String city='',String query='',String category='All',bool savedOnly=false,Map<String,dynamic>? before}) async {
  requests.add({'listing_kind':kind,'query_text':query});return [];
 }
 @override dynamic noSuchMethod(Invocation invocation)=>throw UnimplementedError();
}
void main() {
 testWidgets('seller editor preserves entered fields after a revision conflict', (tester) async {
  final accounts=fixtures.FakeAccounts();accounts.restored.complete(const AccountSummary(id:fixtures.owner,displayName:'Seller'));
  final api=FakeMarket();final backend=BackendSession(accounts:accounts,drafts:fixtures.FakeDrafts(),social:api);
  await tester.pumpWidget(BackendScope(session:backend,child:MaterialApp(theme:NightTheme.light,home:EditListingPage(api:api,row:{'id':'offer','owner_id':fixtures.owner,'title':'Car','description':'Details','city':'Dubai','currency':'AED','price_minor':10000,'revision':3,'kind':'sale'}))));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first,'Updated car');
  await tester.ensureVisible(find.text('Save changes'));await tester.tap(find.text('Save changes'));await tester.pumpAndSettle();
  expect(api.edited?['revision'],3);expect(api.edited?['title'],'Updated car');
  expect(find.textContaining('The offer may have changed'),findsOneWidget);
  expect(find.text('Updated car'),findsOneWidget);
  await tester.pumpWidget(const SizedBox());backend.dispose();await accounts.dispose();
 });

  for (final dark in [false, true]) {
    testWidgets('live marketplace filters on narrow ${dark ? 'dark' : 'light'} screen', (tester) async {
      final api = FakeMarket();
      tester.view.physicalSize = const Size(320,800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: dark ? NightTheme.data : NightTheme.light,
        home: Scaffold(body: MediaQuery(data: const MediaQueryData(size: Size(320,800),textScaler: TextScaler.linear(1.5)),
          child: LiveMarketplace(api: api,kind:'sale')))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('No matching listings yet'), 250, scrollable: find.byType(Scrollable).first);
      expect(find.text('No matching listings yet'),findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first,'Civic');
      await tester.pump(const Duration(milliseconds:500));
      await tester.pumpAndSettle();
      expect(api.requests.last['query_text'],'Civic');
      expect(api.requests.last['listing_kind'],'sale');
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('market money uses exact currency minor units', () {
    expect(parseMarketPrice('12.34', 'USD'), 1234);
    expect(parseMarketPrice('12', 'JPY'), 12);
    expect(parseMarketPrice('12.5', 'JPY'), isNull);
    expect(parseMarketPrice('12.345', 'KWD'), 12345);
    expect(parseMarketPrice('0', 'USD'), isNull);
    expect(parseMarketPrice('-1', 'USD'), isNull);
    expect(parseMarketPrice('12.345', 'USD'), isNull);
    expect(parseMarketPrice('1e9', 'USD'), isNull);
    expect(
      marketPrice({'currency': 'JPY', 'price_minor': 1200, 'kind': 'sale'}),
      'JPY 1200',
    );
    expect(
      marketPrice({'currency': 'KWD', 'price_minor': 12001, 'kind': 'rental'}),
      'KWD 12.001 / day',
    );
  });
}
