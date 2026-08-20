import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();

  // Observable variables
  var isLoading = false.obs;
  var username = ''.obs;
  var password = ''.obs;
  var isLoggedIn = false.obs;
  var errorMessage = ''.obs;
  var obscurePassword = true.obs;

  // Login
  Future<void> login() async {
    if (username.value.trim().isEmpty || password.value.trim().isEmpty) {
      errorMessage.value = 'Please enter both username and password';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _sheets.init();

      // Get users from Google Sheets
      final userData = await _sheets.getSheetDataWithHeaders('Users');

      if (userData.isEmpty) {
        errorMessage.value = 'No users found. Please complete setup.';
        return;
      }

      // Find user
      final users = _parseUsers(userData);
      final user = users.firstWhere(
            (u) => u.username == username.value.trim() &&
            u.password == password.value.trim(),
        orElse: () => null as User,
      );

      if (user != null) {
        // Save login session
        await _prefs.saveLoginSession(username.value.trim());
        isLoggedIn.value = true;

        Get.snackbar(
          'Welcome Back!',
          'Login successful',
          colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        // Navigate to dashboard
        Get.offAllNamed('/dashboard');
      } else {
        errorMessage.value = 'Invalid username or password';
        Get.snackbar(
          'Login Failed',
          'Invalid username or password',
          colorText: Colors.red,
            snackPosition: SnackPosition.BOTTOM
        );
      }

    } catch (e) {
      errorMessage.value = 'Error during login: $e';
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

  List<User> _parseUsers(Map<String, List<dynamic>> data) {
    final users = <User>[];

    if (data['Username'] == null) return users;

    final usernames = data['Username'] ?? [];
    final passwords = data['Password'] ?? [];
    final ids = data['ID'] ?? [];
    final dates = data['Created At'] ?? [];

    for (int i = 0; i < usernames.length; i++) {
      users.add(User(
        id: i < ids.length ? ids[i]?.toString() ?? '' : '',
        username: usernames[i]?.toString() ?? '',
        password: passwords[i]?.toString() ?? '',
        createdAt: i < dates.length ? dates[i]?.toString() ?? '' : '',
      ));
    }

    return users;
  }

  // Inside class AuthController extends GetxController

  /// Verifies if the provided password matches the currently logged-in user
  Future<bool> verifyUserPassword(String enteredPassword) async {
    final trimmedPassword = enteredPassword.trim();
    if (trimmedPassword.isEmpty) return false;

    try {
      // 1. Get current logged-in username from SharedPreferences
      final currentUsername = _prefs.getUsername() ?? username.value;

      if (currentUsername.isEmpty) {
        return false;
      }

      // 2. Fetch fresh user data from Google Sheets
      await _sheets.init();
      final userData = await _sheets.getSheetDataWithHeaders('Users');

      if (userData.isEmpty) return false;

      // 3. Parse and locate current user
      final users = _parseUsers(userData);

      // Check if any user matches BOTH current username and entered password
      final isValid = users.any(
            (u) => u.username == currentUsername && u.password == trimmedPassword,
      );

      return isValid;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }
  // Logout
  Future<void> logout() async {
    try {
      await _prefs.clearLoginSession();
      isLoggedIn.value = false;

      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully',
        colorText: Colors.blue,
          snackPosition: SnackPosition.BOTTOM
      );

      Get.offAllNamed('/login');
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    isLoggedIn.value = _prefs.isLoggedIn();

    if (isLoggedIn.value) {
      username.value = _prefs.getUsername() ?? '';
    }
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }
}