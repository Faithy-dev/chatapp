import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AppThemeColor color;

  ThemeState({
    this.themeMode = ThemeMode.system,
    this.color = AppThemeColor.blue,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppThemeColor? color,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      color: color ?? this.color,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark');
    final isRed = prefs.getBool('isRed');

    ThemeMode mode = ThemeMode.system;
    if (isDark != null) {
      mode = isDark ? ThemeMode.dark : ThemeMode.light;
    }

    AppThemeColor color = AppThemeColor.blue;
    if (isRed != null && isRed) {
      color = AppThemeColor.red;
    }

    state = state.copyWith(themeMode: mode, color: color);
  }

  Future<void> toggleThemeMode() async {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', newMode == ThemeMode.dark);
  }

  Future<void> setThemeColor(AppThemeColor color) async {
    state = state.copyWith(color: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRed', color == AppThemeColor.red);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
