import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/core/session.dart';
import 'package:cars_night/ui/profile.dart';
import 'package:cars_night/ui/marketplace.dart';
import 'package:cars_night/domain/models.dart';

void main() {
  const enabled=bool.fromEnvironment('GENERATE_PREVIEWS');
  for(final dark in [false,true]) {
    for(final page in ['profile','buy','rent']) {
      testWidgets('$page ${dark?'dark':'light'} preview', (tester) async {
        final font=File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
        if(font.existsSync()) {
          final loader=FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
          await loader.load();
        }
        tester.view.physicalSize=const Size(390,1000);tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        final session=DemoSession();addTearDown(session.dispose);
        await tester.pumpWidget(MaterialApp(theme:dark?NightTheme.data:NightTheme.light,home:Scaffold(
          appBar:AppBar(title:const Text('Cars Night')),
          body:RepaintBoundary(key:const ValueKey('design-preview'),child:page=='profile'?ProfilePage(session:session):MarketplacePage(kind:page=='buy'?ListingKind.sale:ListingKind.rental,session:session)),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        await expectLater(find.byKey(const ValueKey('design-preview')),matchesGoldenFile('previews/$page-${dark?'dark':'light'}.png'));
      },skip:!enabled);
    }
  }
}
