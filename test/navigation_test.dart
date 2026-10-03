import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/app.dart';
import 'package:cars_night/ui/components.dart';
import 'package:cars_night/core/session.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/domain/models.dart';
import 'package:cars_night/ui/information.dart';
import 'package:cars_night/ui/marketplace.dart';
import 'package:cars_night/ui/profile.dart';
import 'package:cars_night/ui/messages.dart';

Future<void> openDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const CarsNightApp());
  await tester.ensureVisible(find.text('Get Started'));
  await tester.tap(find.text('Get Started'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome hero starts at top even with a status-bar inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: NightTheme.data,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(360, 800),
            padding: EdgeInsets.only(top: 28, bottom: 24),
          ),
          child: WelcomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(AssetPhoto).first).dy, 0);
    await tester.ensureVisible(find.text('Get Started'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'primary navigation prioritizes community and combines marketplace',
    (tester) async {
      await openDemo(tester);
      expect(find.byKey(const ValueKey('nav-messages')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-marketplace')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-buy')), findsNothing);
      expect(find.byKey(const ValueKey('nav-rent')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('nav-messages')));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to message'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('buy search has a recoverable empty state', (tester) async {
    await openDemo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-marketplace')));
    await tester.pumpAndSettle();
    expect(find.text('Find Your Dream Car'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('search-sale')),
      'no-such-car',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching cars'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset filters'));
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Lamborghini Huracán'), 200,
      scrollable: find.descendant(of: find.byType(MarketplacePage).first, matching: find.byType(Scrollable)).first);
    expect(find.text('Lamborghini Huracán'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image composer returns to feed with a local post', (
    tester,
  ) async {
    await openDemo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('post-caption')),
      'My night drive',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('sample-image-0')));
    await tester.tap(find.byKey(const ValueKey('sample-image-0')));
    await tester.ensureVisible(find.text('Add to demo feed'));
    await tester.tap(find.text('Add to demo feed'));
    await tester.pumpAndSettle();
    expect(find.text('My night drive'), findsOneWidget);
    expect(
      find.text('Added to the local demo feed. Nothing was uploaded.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a saved car immediately updates the collection', (
    tester,
  ) async {
    final session = DemoSession()..toggleSaved('sale-1');
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: NightTheme.data,
        home: SavedPage(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Unsave car'));
    await tester.pumpAndSettle();
    expect(find.text('Keep your favorites close'), findsOneWidget);
    expect(session.savedCount, 0);
  });

  testWidgets('rental city and date controls are available', (tester) async {
    await openDemo(tester);
    await tester.tap(find.byKey(const ValueKey('nav-marketplace')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('market-rent')));
    await tester.pumpAndSettle();
    expect(find.text('Rent a Car'), findsOneWidget);
    expect(find.text('Pick-up date'), findsOneWidget);
    expect(find.text('Drop-off date'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('rental-location')),
      'London',
    );
    await tester.pumpAndSettle();
    expect(find.text('No matching cars'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screens with large text do not report layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = DemoSession();
    addTearDown(session.dispose);
    for (final page in <Widget>[
      const WelcomePage(),
      const AppShell(),
      Scaffold(
        body: MarketplacePage(kind: ListingKind.rental, session: session),
      ),
      const PlanPage(),
      Scaffold(body: MarketplaceHub(session: session)),
      const Scaffold(body: MessagesPage()),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: NightTheme.data,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(1.6),
            ),
            child: page,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
