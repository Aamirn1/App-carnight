import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Appearance extends ChangeNotifier {
  Appearance({ThemeMode initial = ThemeMode.dark}) : _mode = initial;
  ThemeMode _mode;
  ThemeMode get mode => _mode;
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = switch (prefs.getString('carsnight.appearance')) {
        'light' => ThemeMode.light, 'system' => ThemeMode.system, _ => ThemeMode.dark,
      };
      notifyListeners();
    } catch (_) { /* Keep the existing dark default if preferences cannot load. */ }
  }
  Future<void> select(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('carsnight.appearance', value.name)) {
      throw StateError('Could not save appearance');
    }
    _mode = value;
    notifyListeners();
  }
}

class AppearanceScope extends InheritedNotifier<Appearance> {
  const AppearanceScope({super.key, required Appearance controller, required super.child}) : super(notifier: controller);
  static Appearance? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
