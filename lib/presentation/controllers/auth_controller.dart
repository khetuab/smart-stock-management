import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/views/auth/customer_welcome_screen.dart';
import '../../data/models/user_model.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/shared_preferences_service.dart';

class AuthController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();

  /// Static getter for clean global access across screens/controllers
  static AuthController get to {
    if (Get.isRegistered<AuthController>()) return Get.find<AuthController>();
    return Get.put(AuthController(), permanent: true);
  }

  // Observable variables
  var isLoading = false.obs;
  var username = ''.obs;
  var password = ''.obs;
  var phone = ''.obs;
  var isLoggedIn = false.obs;
  var errorMessage = ''.obs;
  var obscurePassword = true.obs;

  // 'admin' or 'customer' — set from the 'Role' column of the Users sheet
  var role = 'customer'.obs;

  // Directly driven by the role observable
  bool get isAdmin => role.value.trim().toLowerCase() == 'admin';

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus().then((_) {
      if (!isLoggedIn.value) {
        _assignSilentGuest();
      }
    });
  }

  bool _isConnectionError(dynamic e) {
    if (e is SocketException) return true;
    if (e is TimeoutException) return true;
    if (e is HttpException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection timed out') ||
        msg.contains('connection refused') ||
        msg.contains('clientexception'); // common with http package on no-network
  }
  String _friendlyError(dynamic e, {String fallback = 'Something went wrong. Please try again.'}) {
    return _isConnectionError(e) ? 'Connection error, try again' : fallback;
  }

  Future<void> _assignSilentGuest() async {
    final deviceId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.saveLoginSession(deviceId);
    await _prefs.saveRole('customer');
    await _prefs.saveDeviceRole('customer');
    username.value = deviceId;
    role.value = 'customer';
    isLoggedIn.value = true;
  }

  // Check login status & restore persistent session
  Future<void> checkLoginStatus() async {
    isLoggedIn.value = _prefs.isLoggedIn();

    if (isLoggedIn.value) {
      username.value = _prefs.getUsername() ?? '';
      role.value = _prefs.getRole() ?? 'customer';
    }
  }

  /// All accounts in the Users sheet — used by the admin's User
  /// Management screen only.
  Future<List<User>> getAllUsers() async {
    await _sheets.init();
    final data = await _sheets.getSheetDataWithHeaders('Users');
    return _parseUsers(data);
  }

  /// Promotes/demotes an account's Role in place. Guards against an
  /// admin accidentally removing their OWN admin access, and against
  /// leaving the store with zero admin accounts entirely.
  Future<bool> setUserRole(String targetUsername, String newRole) async {
    if (targetUsername.trim().toLowerCase() == username.value.trim().toLowerCase() && newRole != 'admin') {
      Get.snackbar('Not Allowed', "You can't remove your own admin access.",
          colorText: Colors.white, backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      await _sheets.init();
      final data = await _sheets.getSheetDataWithHeaders('Users');
      final usernames = List<String>.from((data['Username'] ?? []).map((e) => e.toString()));
      final roles = List<String>.from((data['Role'] ?? []).map((e) => e.toString()));

      final idx = usernames.indexWhere((u) => u.trim().toLowerCase() == targetUsername.trim().toLowerCase());
      if (idx == -1) return false;

      if (newRole != 'admin') {
        final adminCount = roles.where((r) => r.trim().toLowerCase() == 'admin').length;
        final targetIsAdmin = idx < roles.length && roles[idx].trim().toLowerCase() == 'admin';
        if (targetIsAdmin && adminCount <= 1) {
          Get.snackbar('Not Allowed', 'There must be at least one admin account !.',
              colorText: Colors.white, backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
          return false;
        }
      }

      List<dynamic> col(String key) => data[key] ?? [];
      dynamic at(String key) => idx < col(key).length ? col(key)[idx] : '';

      final rowData = [at('ID'), at('Username'), at('Password'), at('Created At'), newRole, at('Phone')];
      final rowIndex = idx + 2; // +1 header row, +1 one-based indexing

      await _sheets.updateRow(sheetName: 'Users', rowIndex: rowIndex, rowData: rowData);
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }
  // ==================== UNIFIED LOGIN ====================
  /// Core login supporting form fields OR passed parameters.
  /// Handles both 'admin' and 'customer' lookup via Google Sheets.
  Future<void> login({String? enteredUsername, String? enteredPassword}) async {
    final userToLogin = (enteredUsername ?? username.value).trim();
    final passToLogin = (enteredPassword ?? password.value).trim();

    if (userToLogin.isEmpty || passToLogin.isEmpty) {
      errorMessage.value = 'Please enter both username and password';
      _showSnackbar('Login Failed', errorMessage.value, isError: true);
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _sheets.init();

      // Fetch user data from sheet
      final userData = await _sheets.getSheetDataWithHeaders('Users');

      if (userData.isEmpty) {
        errorMessage.value = 'No users found. Please complete setup.';
        _showSnackbar('Error', errorMessage.value, isError: true);
        return;
      }

      final usernames = List<String>.from((userData['Username'] ?? []).map((e) => e.toString()));
      final passwords = List<String>.from((userData['Password'] ?? []).map((e) => e.toString()));
      final roles = List<String>.from((userData['Role'] ?? []).map((e) => e.toString()));
      final phones = List<String>.from((userData['Phone'] ?? []).map((e) => e.toString()));

      // Locate matching user case-insensitively
      final index = usernames.indexWhere(
            (u) => u.trim().toLowerCase() == userToLogin.toLowerCase(),
      );

      if (index != -1 && index < passwords.length && passwords[index] == passToLogin) {
        final matchedRole = index < roles.length ? roles[index].trim().toLowerCase() : 'customer';

        // Update Controller State
        username.value = userToLogin;
        phone.value = index < phones.length ? phones[index] : '';
        role.value = matchedRole;
        isLoggedIn.value = true;

        // Save persistent local storage session
        await _prefs.saveLoginSession(userToLogin);
        await _prefs.saveRole(matchedRole);
        if (isAdmin) {
          await _prefs.saveDeviceRole('admin');
        }

        _showSnackbar('Welcome Back!', 'Login successful', isError: false);

        // Navigate based on assigned role
        Get.offAllNamed(isAdmin ? '/dashboard' : '/customer-home');
      } else {
        errorMessage.value = 'Invalid username or password, please try again';
        _showSnackbar('Login Failed', errorMessage.value, isError: true);
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e, fallback: 'Error during login. Please try again.');
      _showSnackbar('Login Failed', errorMessage.value, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== CUSTOMER REGISTRATION ====================
  Future<void> registerCustomer({
    required String username,
    required String password,
    required String phone,
  }) async {
    final trimmedUsername = username.trim();
    final trimmedPassword = password.trim();
    final trimmedPhone = phone.trim();

    if (trimmedUsername.isEmpty || trimmedPassword.isEmpty || trimmedPhone.isEmpty) {
      errorMessage.value = 'Please fill in all fields';
      return;
    }
    if (trimmedPassword.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _sheets.init();
      await _sheets.createSheetIfNotExists('Users');

      final data = await _sheets.getSheetDataWithHeaders('Users');
      final usernames = List<String>.from((data['Username'] ?? []).map((e) => e.toString()));

      // Duplicate Username Guard
      final alreadyTaken = usernames.any((u) => u.trim().toLowerCase() == trimmedUsername.toLowerCase());
      if (alreadyTaken) {
        errorMessage.value = 'That username is already taken. Please choose another.';
        return;
      }

      final ids = List<dynamic>.from(data['ID'] ?? []);
      final nextId = ids.length + 1;

      await _sheets.appendToSheet(
        sheetName: 'Users',
        rowData: [
          nextId.toString(),
          trimmedUsername,
          trimmedPassword,
          DateTime.now().toIso8601String(),
          'customer',
          trimmedPhone,
        ],
        defaultHeaders: ['ID', 'Username', 'Password', 'Created At', 'Role', 'Phone'],
      );

      this.username.value = trimmedUsername;
      this.phone.value = trimmedPhone;
      this.role.value = 'customer';
      this.isLoggedIn.value = true;

      await _prefs.saveLoginSession(trimmedUsername);
      await _prefs.saveRole('customer');
      await _prefs.saveDeviceRole('customer');

      _showSnackbar('Registration Successful', 'Welcome to the app!', isError: false);
      Get.offAllNamed('/customer-home');
    } catch (e) {
      errorMessage.value = _friendlyError(e, fallback: 'Registration failed. Please try again.');
      _showSnackbar('Error', errorMessage.value, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== GUEST CUSTOMER LOGIN ====================
  Future<void> loginAsGuestCustomer({required String name, required String phone}) async {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
      errorMessage.value = 'Please enter your name and phone number';
      return;
    }
    errorMessage.value = '';

    await _prefs.saveGuestCustomer(name: trimmedName, phone: trimmedPhone);
    await _prefs.saveDeviceRole('customer');
    await _prefs.saveLoginSession(trimmedPhone);
    await _prefs.saveRole('customer');

    username.value = trimmedPhone;
    this.phone.value = trimmedPhone;
    role.value = 'customer';
    isLoggedIn.value = true;

    Get.offAllNamed('/customer-home');
  }

  // ==================== PASSWORD VERIFICATION ====================
  Future<bool> verifyUserPassword(String enteredPassword) async {
    final trimmedPassword = enteredPassword.trim();
    if (trimmedPassword.isEmpty) return false;

    try {
      final currentUsername = _prefs.getUsername() ?? username.value;
      if (currentUsername.isEmpty) return false;

      await _sheets.init();
      final userData = await _sheets.getSheetDataWithHeaders('Users');
      if (userData.isEmpty) return false;

      final users = _parseUsers(userData);
      return users.any(
            (u) => u.username.toLowerCase() == currentUsername.toLowerCase() && u.password == trimmedPassword,
      );
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  // ==================== LOGOUT OPERATIONS ====================
  /// Admin/Owner Logout -> routes to `/login`
  Future<void> logout() async {
    try {
      await _prefs.clearLoginSession();
      isLoggedIn.value = false;
      username.value = '';
      phone.value = '';
      role.value = 'customer';

      _showSnackbar('Logged Out', 'You have been logged out successfully', isError: false);
      Get.offAllNamed('/login');
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  /// Guest Customer Logout -> routes to `/role-selection`
  Future<void> logoutGuest() async {
    try {
      await _prefs.clearLoginSession();
      isLoggedIn.value = false;
      username.value = '';
      phone.value = '';
      role.value = 'customer';

      Get.offAll(()=>CustomerWelcomeScreen());
    } catch (e) {
      print('Error ending guest session: $e');
    }
  }

  /// Updates the Phone column of the logged-in user's row in the Users
  /// sheet — this is the actual persistence Edit Profile was missing.
  /// Username is intentionally left uneditable here: it's the join key
  /// for every order's `customerUsername`, so changing it would orphan
  /// the user's own order history.
  Future<bool> updatePhone(String newPhone) async {
    final trimmed = newPhone.trim();
    if (trimmed.isEmpty) return false;

    try {
      isLoading.value = true;
      await _sheets.init();
      final data = await _sheets.getSheetDataWithHeaders('Users');
      final usernames = List<String>.from((data['Username'] ?? []).map((e) => e.toString()));
      final idx = usernames.indexWhere((u) => u == username.value);
      if (idx == -1) return false;

      List<dynamic> col(String key) => data[key] ?? [];
      dynamic at(String key) => idx < col(key).length ? col(key)[idx] : '';

      final rowData = [at('ID'), at('Username'), at('Password'), at('Created At'), at('Role'), trimmed];
      final rowIndex = idx + 2; // +1 for header row, +1 for 1-based indexing

      await _sheets.updateRow(sheetName: 'Users', rowIndex: rowIndex, rowData: rowData);
      phone.value = trimmed;
      return true;
    } catch (e) {
      debugPrint('Error updating phone: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  // ==================== HELPERS & UTILITIES ====================
  List<User> _parseUsers(Map<String, List<dynamic>> data) {
    final users = <User>[];
    if (data['Username'] == null) return users;

    final usernames = data['Username'] ?? [];
    final passwords = data['Password'] ?? [];
    final ids = data['ID'] ?? [];
    final dates = data['Created At'] ?? [];
    final roles = data['Role'] ?? [];

    for (int i = 0; i < usernames.length; i++) {
      users.add(User(
        id: i < ids.length ? ids[i]?.toString() ?? '' : '',
        username: usernames[i]?.toString() ?? '',
        password: passwords[i]?.toString() ?? '',
        role: i < roles.length ? (roles[i]?.toString().trim() ?? '') : '',
        createdAt: i < dates.length ? dates[i]?.toString() ?? '' : '',
      ));
    }
    return users;
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  void clearError() => errorMessage.value = '';

  void _showSnackbar(String title, String message, {required bool isError}) {
    Get.snackbar(
      title,
      message,
      colorText: isError ? Colors.red : Colors.green,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}