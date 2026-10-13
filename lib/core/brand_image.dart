import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'assets.dart';

/// Preserve the original lettering, alpha and every coloured gradient pixel.
/// Only neutral bright ink is changed for rendering on a light surface.
Uint8List lightBrandPixels(Uint8List source) {
  final pixels = Uint8List.fromList(source);
  for (var i = 0; i + 3 < pixels.length; i += 4) {
    if (pixels[i + 3] > 0 && pixels[i] * 255 >= 200 * pixels[i + 3] && pixels[i] == pixels[i + 1] && pixels[i] == pixels[i + 2]) {
      pixels[i] = 0;
      pixels[i + 1] = 0;
      pixels[i + 2] = 0;
    }
  }
  return pixels;
}

abstract final class BrandImage {
  static Future<ui.Image>? _light;
  static Future<ui.Image> get light => _light ??= _load();
  static Future<ui.Image> _load() async {
    final data = await rootBundle.load(NightAssets.wordmark);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final frame = await codec.getNextFrame();
    codec.dispose();
    final original = frame.image;
    try {
      final rgba = await original.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) throw StateError('Brand image could not be decoded');
      final buffer = await ui.ImmutableBuffer.fromUint8List(lightBrandPixels(rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes)));
      final descriptor = ui.ImageDescriptor.raw(buffer, width: original.width, height: original.height, pixelFormat: ui.PixelFormat.rgba8888);
      try {
        final output = await descriptor.instantiateCodec();
        try { return (await output.getNextFrame()).image; }
        finally { output.dispose(); }
      } finally { descriptor.dispose(); buffer.dispose(); }
    } finally { original.dispose(); }
  }
}
