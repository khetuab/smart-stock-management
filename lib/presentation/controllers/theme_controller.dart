import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/themes/app_theme.dart';
import '../../data/services/shared_preferences_service.dart';

/// Manages the app's dark/light/system theme preference and brand seed color.
///
/// This controller is registered permanently in [AppBindings] so it stays
/// alive for the whole app lifetime.
class ThemeController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  static const String modeKey = 'themeMode'; // 'system' | 'light' | 'dark'
  static const String seedKey = 'themeColor'; // '#RRGGBB' — shared with SetupController

  // Observable state
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<Color> seedColor = AppTheme.defaultSeed.obs;

  // Computed themes
  ThemeData get lightTheme => AppTheme.light(seedColor: seedColor.value);
  ThemeData get darkTheme => AppTheme.dark(seedColor: seedColor.value);

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  /// Restore saved theme preferences from SharedPreferences
  Future<void> _restore() async {
    try {
      final savedMode = await _prefs.getString(modeKey);
      final savedColor = await _prefs.getString(seedKey);

      if (savedMode != null && savedMode.isNotEmpty) {
        themeMode.value = _modeFromString(savedMode);
      }
      if (savedColor != null && savedColor.isNotEmpty) {
        seedColor.value = AppTheme.colorFromHex(savedColor);
      }

      // Apply the restored theme
      Get.changeThemeMode(themeMode.value);
    } catch (_) {
      // First run / no prefs yet — defaults above already apply.
    }
  }

  /// Set the theme mode (light, dark, or system) and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _prefs.setString(modeKey, _modeToString(mode));
  }

  /// Toggle between light and dark mode (convenience method)
  Future<void> toggleTheme() async {
    if (themeMode.value == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (themeMode.value == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // If system, check current brightness and toggle to the opposite
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      if (brightness == Brightness.dark) {
        await setThemeMode(ThemeMode.light);
      } else {
        await setThemeMode(ThemeMode.dark);
      }
    }
  }

  /// Update the brand seed color and persist it
  Future<void> setSeedColor(String hex, {bool persist = true}) async {
    seedColor.value = AppTheme.colorFromHex(hex);
    if (persist) {
      await _prefs.setString(seedKey, hex);
    }
  }

  /// Get the current theme mode as a string for persistence
  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Convert string to ThemeMode
  ThemeMode _modeFromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Check if dark mode is currently active
  bool get isDarkMode {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    // System mode - check platform brightness
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  /// Get the current brightness (for conditional styling)
  Brightness get currentBrightness {
    return isDarkMode ? Brightness.dark : Brightness.light;
  }
}