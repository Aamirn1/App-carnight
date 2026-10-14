import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cars_night/backend/social.dart';
import 'package:cars_night/ui/live_market.dart';
import 'package:cars_night/core/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/backend/market.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('live marketplace filters on narrow ${dark ? 'dark' : 'light'} screen', (tester) async {
      final requests = <Map<String,dynamic>>[];
      final client = SupabaseClient('https://example.supabase.co', 'public-test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests.add(jsonDecode(request.body) as Map<String,dynamic>);
          return http.Response('[]', 200, headers: {'content-type':'application/json'});
        }));
      tester.view.physicalSize = const Size(320,800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: dark ? NightTheme.data : NightTheme.light,
        home: Scaffold(body: MediaQuery(data: const MediaQueryData(size: Size(320,800),textScaler: TextScaler.linear(1.5)),
          child: LiveMarketplace(api: SocialRepository(client),kind:'sale')))));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('No matching listings yet'), 250, scrollable: find.byType(Scrollable).first);
      expect(find.text('No matching listings yet'),findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first,'Civic');
      await tester.pump(const Duration(milliseconds:500));
      await tester.pumpAndSettle();
      expect(requests.last['query_text'],'Civic');
      expect(requests.last['listing_kind'],'sale');
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(client.dispose);
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
