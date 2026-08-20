import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/zakat_controller.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/backup_service.dart';
import '../../localization/locale_controller.dart';
import 'auth_controller.dart';
import 'dashboard_controller.dart';

class SettingsController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final BackupService _backup = BackupService();
  final AuthController _auth = Get.find<AuthController>();
  final DashboardController _dashboard = Get.find<DashboardController>();

  var isLoading = false.obs;

  // Store info
  var storeName = ''.obs;
  var storeLogo = ''.obs;
  var ownerName = ''.obs;
  var currency = ''.obs;
  var language = ''.obs;
  var themeColor = ''.obs;
  var zakatEnabled = false.obs;

  // Password change
  var currentPassword = ''.obs;
  var newPassword = ''.obs;
  var confirmNewPassword = ''.obs;
  var showPasswordChange = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    print('📊 [SETTINGS] Loading settings from SharedPreferences...');

    storeName.value = _prefs.getString('storeName') ?? '';
    storeLogo.value = _prefs.getString('storeLogo') ?? '';
    ownerName.value = _prefs.getString('ownerName') ?? '';
    currency.value = _prefs.getString('currency') ?? 'ETB';
    language.value = _prefs.getString('language') ?? 'English';
    themeColor.value = _prefs.getString('themeColor') ?? '#2196F3';
    zakatEnabled.value = _prefs.getBool('zakatEnabled') ?? false;

    print('📊 [SETTINGS] Store Name: ${storeName.value}');
    print('📊 [SETTINGS] Theme Color: ${themeColor.value}');
    print('📊 [SETTINGS] Currency: ${currency.value}');
    print('📊 [SETTINGS] Zakat Enabled: ${zakatEnabled.value}');
  }

  Future<void> updateStoreInfo({
    String? storeName,
    String? ownerName,
    String? currency,
    String? language,
  }) async {
    try {
      isLoading.value = true;

      if (storeName != null) {
        this.storeName.value = storeName;
        await _prefs.setString('storeName', storeName);
      }

      if (ownerName != null) {
        this.ownerName.value = ownerName;
        await _prefs.setString('ownerName', ownerName);
      }

      if (currency != null) {
        this.currency.value = currency;
        await _prefs.setString('currency', currency);
      }

      if (language != null) {
        this.language.value = language;
        await _prefs.setString('language', language);
      }

      // Update in Google Sheets
      await _updateStoreInfoInSheets();

      // Update dashboard
      _dashboard.loadStoreInfo();

      Get.snackbar(
        'Success',
        'Store information updated successfully',
        colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM
      );

    } catch (e) {
      print('Error updating store info: $e');
      Get.snackbar(
        'Error',
        'Failed to update store information: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateStoreInfoInSheets() async {
    try {
      await _sheets.init();

      final headers = ['Store Name', 'Store Logo', 'Owner Name', 'Currency', 'Language', 'Zakat Enabled', 'Theme Color', 'Setup Date'];
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
          DateTime.now().toIso8601String(),
        ]
      ];

      await _sheets.clearSheet('StoreInfo');
      await _sheets.writeToSheet(
        sheetName: 'StoreInfo',
        values: values,
      );

    } catch (e) {
      print('Error updating store info in sheets: $e');
      rethrow;
    }
  }

  Future<void> changeThemeColor(String color) async {
    themeColor.value = color;
    await _prefs.setString('themeColor', color);
    await _updateStoreInfoInSheets();

    // Update dashboard
    _dashboard.themeColor.value = color;

    Get.snackbar(
      'Success',
      'Theme color updated successfully',
      snackPosition: SnackPosition.BOTTOM,
      colorText: Colors.green,
    );
  }

  Future<void> changeLogo(String logoUrl) async {
    storeLogo.value = logoUrl;
    await _prefs.setString('storeLogo', logoUrl);
    await _updateStoreInfoInSheets();

    // Update dashboard
    _dashboard.storeLogo.value = logoUrl;

    Get.snackbar(
      'Success',
      'Logo updated successfully',
      colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM
    );
  }

  Future<void> changeLanguage(String lang) async {
    language.value = lang;

    // Applies instantly app-wide and persists — this is the fix.
    // No more "please restart the app".
    await LocaleController.to.setLocale(lang, persist: true);

    await _updateStoreInfoInSheets();

    Get.snackbar(
      'success'.tr,
      'languageChangedSuccess'.tr,
      colorText: Colors.green,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM
    );
  }

  // Inside SettingsController:
  Future<void> toggleZakat(bool value) async {
    try {
      isLoading.value = true;

      // 1. Update SharedPreferences
      await _prefs.setBool('zakatEnabled', value);

      // 2. Update local state
      zakatEnabled.value = value;

      // 3. Update DashboardController
      _dashboard.zakatEnabled.value = value;

      // 4. Update ZakatController if registered
      if (Get.isRegistered<ZakatController>()) {
        final zakatController = Get.find<ZakatController>();

        // Update the observable
        zakatController.isZakatEnabled.value = value;

        // If enabled, load data; if disabled, clear data
        if (value) {
          await zakatController.loadInventoryValue();
        } else {
          // Clear zakat data when disabled
          zakatController.inventoryValue.value = 0.0;
          zakatController.cashBalance.value = 0.0;
          zakatController.bankBalance.value = 0.0;
          zakatController.goldValue.value = 0.0;
          zakatController.silverValue.value = 0.0;
          zakatController.otherAssets.value = 0.0;
          zakatController.totalAssets.value = 0.0;
          zakatController.zakatDue.value = 0.0;
          zakatController.isAboveNisab.value = false;
        }
      }

      // 5. Update StoreInfo in Google Sheets
      await _updateStoreInfoInSheets();

      // 6. Show feedback
      Get.snackbar(
        value ? 'Zakat Enabled' : 'Zakat Disabled',
        value
            ? 'Zakat calculation feature has been enabled'
            : 'Zakat calculation feature has been disabled',
        snackPosition: SnackPosition.BOTTOM,
        colorText: value ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      print('Error toggling zakat: $e');
      Get.snackbar(
        'Error',
        'Failed to toggle zakat feature: $e',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> changePassword() async {
    // Validate empty fields
    if (currentPassword.value.trim().isEmpty ||
        newPassword.value.trim().isEmpty ||
        confirmNewPassword.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all password fields',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    // Validate match
    if (newPassword.value != confirmNewPassword.value) {
      Get.snackbar(
        'Error',
        'New passwords do not match',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    // Validate length
    if (newPassword.value.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    try {
      isLoading.value = true;
      await _sheets.init();

      // Verify current password
      final userData = await _sheets.getSheetDataWithHeaders('Users');
      final usernames = List<String>.from(userData['Username'] ?? []);
      final passwords = List<String>.from(userData['Password'] ?? []);

      final username = _auth.username.value;
      final userIndex = usernames.indexWhere((u) => u == username);

      if (userIndex == -1) {
        Get.snackbar(
          'Error',
          'User not found',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
        return;
      }

      if (userIndex >= passwords.length || passwords[userIndex] != currentPassword.value) {
        Get.snackbar(
          'Error',
          'Current password is incorrect',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
        return;
      }

      // Safely reconstruct users sheet rows
      final allUsers = <List<dynamic>>[];
      final headers = ['ID', 'Username', 'Password', 'Created At'];
      allUsers.add(headers);

      final ids = List<dynamic>.from(userData['ID'] ?? []);
      final createdAts = List<dynamic>.from(userData['Created At'] ?? []);

      for (int i = 0; i < usernames.length; i++) {
        final isTarget = i == userIndex;
        allUsers.add([
          i < ids.length ? ids[i] : (i + 1).toString(),
          usernames[i],
          isTarget ? newPassword.value : (i < passwords.length ? passwords[i] : ''),
          i < createdAts.length ? createdAts[i] : DateTime.now().toIso8601String(),
        ]);
      }

      await _sheets.writeToSheet(
        sheetName: 'Users',
        values: allUsers,
      );

      // Clear reactive fields
      currentPassword.value = '';
      newPassword.value = '';
      confirmNewPassword.value = '';
      showPasswordChange.value = false;

      Get.snackbar(
        'Success',
        'Password changed successfully',
        colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM
      );
    } catch (e) {
      print('Error changing password: $e');
      Get.snackbar(
        'Error',
        'Failed to change password: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> performBackup() async {
    try {
      isLoading.value = true;

      final result = await _backup.createBackup();

      if (result) {
        Get.snackbar(
          'Success',
          'Backup created successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create backup',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      print('Error creating backup: $e');
      Get.snackbar(
        'Error',
        'Failed to create backup: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreBackup(BuildContext context) async {
    try {
      isLoading.value = true;

      final result = await _backup.restoreBackup(context);

      if (result) {
        Get.snackbar(
          'Success',
          'Backup restored successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to restore backup',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      print('Error restoring backup: $e');
      Get.snackbar(
        'Error',
        'Failed to restore backup: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Inside SettingsController (or wherever your reset dialog logic lives)
  Future<bool> verifyUserPassword(String enteredPassword) async {
    final authController = Get.find<AuthController>();
    return await authController.verifyUserPassword(enteredPassword);
  }

  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.logout();
    }
  }

  Future<void> resetApp() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Reset Application'),
        content: const Text(
          'This will delete all data and reset the app to its initial state. This action cannot be undone!',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _prefs.clear();
        await _sheets.clearSheet('Products');
        await _sheets.clearSheet('Sales');
        await _sheets.clearSheet('Categories');
        await _sheets.clearSheet('Purchases');
        await _sheets.clearSheet('Users');
        await _sheets.clearSheet('StoreInfo');
        await _sheets.clearSheet('Zakat');
        await _sheets.clearSheet('Settings');
        await _sheets.clearSheet('Debts');

        Get.snackbar(
          'Success',
          'App reset successfully',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );

        Get.offAllNamed('/setup');

      } catch (e) {
        print('Error resetting app: $e');
        Get.snackbar(
          'Error',
          'Failed to reset app: $e',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }
    }
  }
}