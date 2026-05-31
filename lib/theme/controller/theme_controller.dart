import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeController extends StateNotifier<ThemeMode> {

  ThemeController() : super(ThemeMode.system);

  bool get isDark => state == ThemeMode.dark;

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}

final themeProvider =
StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});