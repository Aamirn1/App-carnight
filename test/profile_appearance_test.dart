import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cars_night/core/appearance.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/core/session.dart';
import 'package:cars_night/ui/profile.dart';
import 'package:cars_night/ui/marketplace.dart';
import 'package:cars_night/domain/models.dart';

void main() {
  test('appearance choice survives a new controller and invalid value uses dark', () async {
    SharedPreferences.setMockInitialValues({});
    final settings=Appearance();
    await settings.select(ThemeMode.light);
    final restarted=Appearance(); await restarted.restore();
    expect(restarted.mode,ThemeMode.light);
    await settings.select(ThemeMode.system); await restarted.restore();
    expect(restarted.mode,ThemeMode.system);
    settings.dispose(); restarted.dispose();
  });
  testWidgets('profile has cover controls and edits preview without invented counts', (tester) async {
    final session=DemoSession(); addTearDown(session.dispose);
    await tester.pumpWidget(MaterialApp(theme:NightTheme.light,home:Scaffold(body:ProfilePage(session:session))));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Change cover'),findsOneWidget);
    expect(find.byTooltip('Change profile photo'),findsOneWidget);
    expect(find.text('—'),findsNWidgets(2));
    await tester.ensureVisible(find.text('Edit profile')); await tester.tap(find.text('Edit profile'));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first,'Night Driver');
    await tester.ensureVisible(find.text('Save profile')); await tester.tap(find.text('Save profile'));await tester.pumpAndSettle();
    expect(find.text('Night Driver'),findsOneWidget);expect(tester.takeException(),isNull);
  });
  for(final kind in ListingKind.values) {
    testWidgets('${kind.name} search precedes a single horizontal filter row on narrow light screens',(tester) async {
      tester.view.physicalSize=const Size(320,800);tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      final session=DemoSession();addTearDown(session.dispose);
      await tester.pumpWidget(MaterialApp(theme:NightTheme.light,home:Scaffold(body:MarketplacePage(kind:kind,session:session))));
      await tester.pumpAndSettle();
      final search=find.byKey(ValueKey('search-${kind.name}'));
      final filters=find.byKey(ValueKey('filters-${kind.name}'));
      expect(tester.getTopLeft(search).dy,lessThan(tester.getTopLeft(filters).dy));
      expect(tester.widget<SingleChildScrollView>(filters).scrollDirection,Axis.horizontal);
      expect(tester.takeException(),isNull);
    });
  }
}
