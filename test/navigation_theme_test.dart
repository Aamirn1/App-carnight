import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/core/theme.dart';

void main() {
  test('selected navigation icon uses cyan instead of black', () {
    final icons = NightTheme.data.navigationBarTheme.iconTheme!;
    expect(icons.resolve({WidgetState.selected})!.color, NightTheme.cyan);
    expect(icons.resolve({})!.color, Colors.white);
  });
}
