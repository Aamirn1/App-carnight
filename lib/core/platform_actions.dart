import 'package:flutter/services.dart';

abstract final class PlatformActions {
  static const _channel = MethodChannel('carsnight/platform');
  static Future<bool> openEmail() async {
    try {
      return await _channel.invokeMethod<bool>('openEmail') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> shareText(String text) async {
    try {
      return await _channel.invokeMethod<bool>('shareText', text) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
