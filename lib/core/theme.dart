import 'package:flutter/material.dart';

/// Provisional reference-inspired tokens, awaiting actual Flutter visual QA.
abstract final class NightTheme {
  static const background = Color(0xFF070A1B);
  static const surface = Color(0xFF14182C);
  static const border = Color(0xFF292E45);
  static const muted = Color(0xFFB9BED0);
  static const cyan = Color(0xFF14B5FF);
  static const violet = Color(0xFF9058FF);
  static const magenta = Color(0xFFE52CEB);
  static const gradient = LinearGradient(colors: [cyan, violet, magenta]);

  static ThemeData get data => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: cyan, secondary: magenta,
      surface: surface, onSurface: Colors.white),
    appBarTheme: const AppBarTheme(backgroundColor: background,
      surfaceTintColor: Colors.transparent, centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20,
        fontWeight: FontWeight.w700)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyan)),
    ),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: background,
      indicatorColor: Color(0xFF302658), height: 72),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white, minimumSize: const Size(48, 48),
      side: const BorderSide(color: border))),
    dividerColor: border,
  );
}
