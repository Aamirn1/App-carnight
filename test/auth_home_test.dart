import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/app.dart';
import 'package:cars_night/backend/repositories.dart';
import 'package:cars_night/backend/session.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/auth.dart';
import 'package:cars_night/data/demo_catalog.dart';
import 'package:cars_night/domain/models.dart';
import 'backend_test.dart' as fixtures;

void main() {
  testWidgets('restored account opens Home and sign-out clears navigation', (tester) async {
    final accounts = fixtures.FakeAccounts();
    final backend = BackendSession(accounts: accounts, drafts: fixtures.FakeDrafts());
    addTearDown(backend.dispose);
    await tester.pumpWidget(CarsNightApp(backend: backend));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    accounts.restored.complete(const AccountSummary(id: fixtures.owner, displayName: 'Driver'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    accounts.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsNothing);
    await accounts.dispose();
  });

  testWidgets('sign-in event replaces Welcome and auth routes with Home', (tester) async {
    final accounts = fixtures.FakeAccounts()..restored.complete(null);
    final backend = BackendSession(accounts: accounts, drafts: fixtures.FakeDrafts());
    addTearDown(backend.dispose);
    await tester.pumpWidget(CarsNightApp(backend: backend));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsWidgets);
    accounts.changes.add(const AccountSummary(id: fixtures.owner, displayName: 'Driver'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    expect(navigator.canPop(), isFalse);
    await accounts.dispose();
  });

  testWidgets('signup succeeds into a dedicated email confirmation screen', (tester) async {
    final accounts = fixtures.FakeAccounts()..restored.complete(null);
    final backend = BackendSession(accounts: accounts, drafts: fixtures.FakeDrafts());
    addTearDown(backend.dispose);
    await tester.pumpWidget(BackendScope(session: backend,
      child: MaterialApp(theme: NightTheme.data, home: const AuthPage(mode: AuthMode.signUp))));
    await tester.pumpAndSettle();
    expect(find.text('Open Gmail'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(0), 'Aamir');
    await tester.enterText(find.byType(TextFormField).at(1), 'Rawalpindi');
    await tester.enterText(find.byType(TextFormField).at(2), 'driver@example.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.ensureVisible(find.byKey(const ValueKey('signup-country')));
    await tester.tap(find.byKey(const ValueKey('signup-country')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Pakistan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pakistan').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Create account'));
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Open Gmail'), findsOneWidget);
    expect(find.text('Display name'), findsNothing);
    expect(find.text('Check your email'), findsOneWidget);
    await accounts.dispose();
  });

  test('location filter never silently falls back to another country', () {
    expect(filterListings(DemoCatalog.listings, kind: ListingKind.sale, countryCode: 'PK', city: 'Rawalpindi'), isEmpty);
    final london = filterListings(DemoCatalog.listings, kind: ListingKind.sale, countryCode: 'GB', city: 'London');
    expect(london, isNotEmpty);
    expect(london.every((car) => car.countryCode == 'GB'), isTrue);
  });
}
