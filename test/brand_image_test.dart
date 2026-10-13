import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:cars_night/core/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/brand_image.dart';
import 'package:cars_night/core/theme.dart';
import 'package:cars_night/ui/components.dart';

void main() {
  test(
    'light logo preserves coloured pixels and alpha including soft edges',
    () {
      final source = Uint8List.fromList([
        255,
        255,
        255,
        255,
        80,
        80,
        80,
        80,
        254,
        255,
        255,
        255,
        20,
        181,
        255,
        255,
        144,
        88,
        255,
        255,
        229,
        44,
        235,
        255,
        0,
        0,
        0,
        0,
      ]);
      expect(lightBrandPixels(source), [
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        80,
        0,
        0,
        0,
        255,
        20,
        181,
        255,
        255,
        144,
        88,
        255,
        255,
        229,
        44,
        235,
        255,
        0,
        0,
        0,
        0,
      ]);
      expect(source[0], 255);
    },
  );
  testWidgets(
    'light theme retains the real image logo without replacement text',
    (tester) async {
      await tester.runAsync(() async {
        final light = await BrandImage.light;
        final asset = await rootBundle.load(NightAssets.wordmark);
        final codec = await ui.instantiateImageCodec(
          asset.buffer.asUint8List(),
        );
        final original = (await codec.getNextFrame()).image;
        final originalData = (await original.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final renderedData = (await light.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final source = originalData.buffer.asUint8List();
        final rendered = renderedData.buffer.asUint8List();
        expect(light.width, original.width);
        expect(light.height, original.height);
        var coloured = 0;
        var changedGradientPixels = 0;
        var changedAlphaPixels = 0;
        for (var i = 0; i < source.length; i += 4) {
          if (rendered[i + 3] != source[i + 3]) changedAlphaPixels++;
          if (math.max(source[i], math.max(source[i + 1], source[i + 2])) -
                  math.min(source[i], math.min(source[i + 1], source[i + 2])) >
              32) {
            coloured++;
            if (rendered[i] != source[i] ||
                rendered[i + 1] != source[i + 1] ||
                rendered[i + 2] != source[i + 2])
              changedGradientPixels++;
          }
        }
        expect(coloured, greaterThan(1000));
        expect(changedGradientPixels, 0);
        expect(changedAlphaPixels, 0);
        original.dispose();
        codec.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: NightTheme.light,
          home: const Scaffold(body: Brand()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(RawImage)), const Size(142, 57));
    },
  );
}
