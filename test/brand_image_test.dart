import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/brand_image.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/components.dart';

void main() {
  test('light logo preserves coloured pixels and alpha including soft edges', () {
    final source = Uint8List.fromList([
      255,255,255,255, 80,80,80,80, 20,181,255,255,
      144,88,255,255, 229,44,235,255, 0,0,0,0,
    ]);
    expect(lightBrandPixels(source), [
      0,0,0,255, 0,0,0,80, 20,181,255,255,
      144,88,255,255, 229,44,235,255, 0,0,0,0,
    ]);
    expect(source[0], 255);
  });
  testWidgets('light theme retains the real image logo without replacement text', (tester) async {
    await tester.runAsync(() async { await BrandImage.light; });
    await tester.pumpWidget(MaterialApp(theme: NightTheme.light, home: const Scaffold(body: Brand())));
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(RawImage)), const Size(142,57));
  });
}
