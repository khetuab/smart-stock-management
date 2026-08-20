import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/shared_preferences_service.dart';

/// Central controller for the app's active language. Mirrors
/// ThemeController's `setSeedColor(persist:)` pattern: switching language
/// applies INSTANTLY across the whole running app via `Get.updateLocale()`
/// — no restart needed — and is optionally persisted to SharedPreferences.
class LocaleController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  /// Human-readable names (used in Settings / Setup wizard dropdowns)
  /// mapped to actual Locale objects.
  static const Map<String, Locale> supported = {
    'English': Locale('en', 'US'),
    'Amharic': Locale('am', 'ET'),
    'Arabic': Locale('ar', 'SA'),
  };

  static LocaleController get to {
    if (Get.isRegistered<LocaleController>()) return Get.find<LocaleController>();
    return Get.put(LocaleController(), permanent: true);
  }

  var languageName = 'English'.obs;
  var locale = const Locale('en', 'US').obs;

  bool get isRtl => locale.value.languageCode == 'ar';

  @override
  void onInit() {
    super.onInit();
    final saved = _prefs.getString('language') ?? 'English';
    languageName.value = saved;
    locale.value = supported[saved] ?? const Locale('en', 'US');
  }

  /// Reads the persisted language BEFORE GetX/any controller exists yet —
  /// used for GetMaterialApp's `locale:` param at first app launch so the
  /// correct language shows from frame one, not just after onInit runs.
  static Locale get initialLocale {
    final prefs = SharedPreferencesService();
    final saved = prefs.getString('language') ?? 'English';
    return supported[saved] ?? const Locale('en', 'US');
  }

  Future<void> setLocale(String newLanguageName, {bool persist = true}) async {
    final newLocale = supported[newLanguageName];
    if (newLocale == null) return;

    languageName.value = newLanguageName;
    locale.value = newLocale;

    // The actual instant switch — GetX rebuilds every `.tr` string
    // app-wide the moment this is called.
    Get.updateLocale(newLocale);

    if (persist) {
      await _prefs.setString('language', newLanguageName);
    }
  }
}