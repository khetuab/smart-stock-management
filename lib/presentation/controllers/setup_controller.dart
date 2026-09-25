import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/settings_controller.dart';
import '../../app/themes/app_theme.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../localization/locale_controller.dart';
import 'auth_controller.dart';
import 'dashboard_controller.dart';
import 'theme_controller.dart';

/// ---------------------------------------------------------------------
/// CHANGES vs your original SetupController — everything else is unchanged:
///
/// 1. Added `themeMode` (Rx<ThemeMode>) + `updateThemeMode()` for the new
///    Light / Dark / System picker in ThemeStep.
/// 2. `updateThemeColor()` now also pushes the color live into
///    ThemeController, so the whole app previews the brand color while
///    the merchant is still in the wizard (not just after completeSetup).
/// 3. `completeSetup()` persists `themeMode` alongside the existing prefs,
///    and applies it via ThemeController.
///
/// Everything else — validation, Google Sheets writes, credentials saving —
/// is copied over as-is from your version.
/// ---------------------------------------------------------------------
class SetupController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Step tracking
  var currentStep = 0.obs;
  final int totalSteps = 5;

  // Store info
  var storeName = ''.obs;
  var ownerName = ''.obs;
  var currency = 'ETB'.obs;
  var language = 'English'.obs;
  var themeColor = '#2563EB'.obs;
  var themeMode = ThemeMode.system.obs; // NEW: 'system' | 'light' | 'dark'
  var storeLogo = ''.obs;
  var zakatEnabled = false.obs;

  // Auth
  var username = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;

  // Loading states
  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;

  // Validation
  var step1Valid = false.obs;
  var step2Valid = false.obs;
  var step3Valid = true.obs;
  var step4Valid = false.obs;
  var step5Valid = false.obs;

  // Error messages
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currency.value = 'ETB';

    // Seed the wizard's color/mode from whatever ThemeController currently
    // holds (e.g. system default) so the ThemeStep preview starts in sync.
    if (Get.isRegistered<ThemeController>()) {
      final theme = Get.find<ThemeController>();
      themeColor.value = AppTheme.colorToHex(theme.seedColor.value);
      themeMode.value = theme.themeMode.value;
    }
  }

  void updateStoreName(String value) {
    storeName.value = value;
    validateStep1();
  }

  void updateOwnerName(String value) {
    ownerName.value = value;
  }

  void updateCurrency(String value) {
    currency.value = value;
  }

  void updateLanguage(String value) {
    language.value = value;
    LocaleController.to.setLocale(value, persist: false);
  }

  void updateThemeColor(String value) {
    themeColor.value = value;

    // Live-preview the brand color across the whole app while still
    // inside the wizard. Not persisted yet — that happens on completeSetup.
    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().setSeedColor(value, persist: false);
    }
  }

  /// NEW: called from the Light / Dark / System cards in ThemeStep.
  void updateThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    if (Get.isRegistered<ThemeController>()) {
      Get.find<ThemeController>().setThemeMode(mode);
    }
  }

  void updateStoreLogo(String value) {
    storeLogo.value = value;
    validateStep2();
  }

  void updateZakatEnabled(bool value) {
    zakatEnabled.value = value;
  }

  void updateUsername(String value) {
    username.value = value;
    validateStep5();
  }

  void updatePassword(String value) {
    password.value = value;
    validateStep5();
  }

  void updateConfirmPassword(String value) {
    confirmPassword.value = value;
    validateStep5();
  }

  void validateStep1() {
    step1Valid.value = storeName.value.trim().isNotEmpty;
  }

  void validateStep2() {
    step2Valid.value = storeLogo.value.isNotEmpty;
  }

  void validateStep5() {
    final isValid = username.value.trim().isNotEmpty &&
        password.value.trim().isNotEmpty &&
        password.value == confirmPassword.value &&
        password.value.length >= 6;
    step5Valid.value = isValid;
  }

  Future<void> nextStep() async {
    if (currentStep.value < totalSteps - 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> uploadLogo() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final imageUrl = await _cloudinary.uploadFromGallery(
        folder: 'store_logos',
        isPublic: true,
      );

      if (imageUrl != null) {
        storeLogo.value = imageUrl;
        validateStep2();

        Get.snackbar(
          'Success',
          'Logo uploaded successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      } else {
        errorMessage.value = 'Failed to upload logo. Please try again.';
      }
    } catch (e) {
      errorMessage.value = 'Error uploading logo: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeSetup() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Save to SharedPreferences
      await _prefs.setString('storeName', storeName.value);
      await _prefs.setString('storeLogo', storeLogo.value);
      await _prefs.setString('themeColor', themeColor.value);
      await _prefs.setString('themeMode', _themeModeToString(themeMode.value)); // NEW
      await _prefs.setString('currency', currency.value);
      await _prefs.setString('language', language.value);
      await _prefs.setBool('zakatEnabled', zakatEnabled.value);
      await _prefs.setString('ownerName', ownerName.value);
      await _prefs.setBool('setupCompleted', true);
      // Persist + apply language choice for real now
      await LocaleController.to.setLocale(language.value, persist: true);

      // Persist + apply theme choices for real now
      if (Get.isRegistered<ThemeController>()) {
        final theme = Get.find<ThemeController>();
        await theme.setSeedColor(themeColor.value, persist: true);
        await theme.setThemeMode(themeMode.value);
      }

      // Save to Google Sheets
      await saveStoreInfoToSheets();

      // Save user credentials
      await saveUserCredentials();

      // Create initial sheets
      await initializeSheets();

      // Save login session
      // Save login session
      await _prefs.saveLoginSession(username.value);

      // FIX: DashboardController was already created (and its onInit
      // already ran) before setup finished, so it's still holding the
      // defaults it read on first launch. Force it to re-read the
      // SharedPreferences values we just saved, otherwise Dashboard shows
      // stale/default info until the app is fully restarted.

      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().username.value = username.value;
      }

      // SettingsController: re-read the SharedPreferences values we
      // just wrote, so Settings screen shows real data instead of "Not set".
      if (Get.isRegistered<SettingsController>()) {
        Get.find<SettingsController>().loadSettings();
      }
      if (Get.isRegistered<DashboardController>()) {
        final dashboard = Get.find<DashboardController>();
        dashboard.loadStoreInfo();
        await dashboard.refreshDashboard();
      }

      Get.snackbar(
        'Success',
        'Setup completed successfully!',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/dashboard');
    } catch (e) {
      errorMessage.value = 'Error completing setup: $e';
      Get.snackbar(
        'Error',
        errorMessage.value,
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveStoreInfoToSheets() async {
    try {
      await _sheets.init();
      await _sheets.createSheetIfNotExists('StoreInfo');

      final headers = [
        'Store Name', 'Store Logo', 'Owner Name', 'Currency',
        'Language', 'Zakat Enabled', 'Theme Color', 'Theme Mode', 'Setup Date'
      ];

      final values = [
        headers,
        [
          storeName.value,
          storeLogo.value,
          ownerName.value,
          currency.value,
          language.value,
          zakatEnabled.value.toString(),
          themeColor.value,
          _themeModeToString(themeMode.value),
          DateTime.now().toIso8601String(),
        ]
      ];

      await _sheets.clearSheet('StoreInfo');
      await _sheets.writeToSheet(sheetName: 'StoreInfo', values: values);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveUserCredentials() async {
    try {
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Users');

      const userHeaders = ['ID', 'Username', 'Password', 'Created At', 'Role'];
      final existingData = await _sheets.readSheet('Users');
      final userId = existingData.length + 1;

      final row = [
        userId.toString(),
        username.value,
        password.value,
        DateTime.now().toIso8601String(),
        'admin', // the account created in the setup wizard is always the store owner
      ];

      if (existingData.isEmpty) {
        await _sheets.writeToSheet(sheetName: 'Users', values: [userHeaders, row]);
      } else {
        // Migrate a stale header row the same way Orders does, then append.
        final currentHeaders = existingData.first.map((h) => h?.toString() ?? '').toList();
        final isUpToDate = currentHeaders.length == userHeaders.length &&
            List.generate(userHeaders.length, (i) => currentHeaders[i] == userHeaders[i])
                .every((m) => m);
        if (!isUpToDate) {
          final allRows = List<List<dynamic>>.from(existingData);
          allRows[0] = userHeaders;
          await _sheets.clearSheet('Users');
          await _sheets.writeToSheet(sheetName: 'Users', values: allRows);
        }
        await _sheets.appendToSheet(sheetName: 'Users', rowData: row);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> initializeSheets() async {
    try {
      await _sheets.init();
      final sheets = ['Products', 'Sales', 'Purchases', 'Zakat', 'Settings', 'Backup'];
      for (var sheet in sheets) {
        await _sheets.createSheetIfNotExists(sheet);
      }
    } catch (e) {
      rethrow;
    }
  }

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return step1Valid.value;
      case 1:
        return step2Valid.value;
      case 4:
        return step5Valid.value;
      default:
        return true;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}