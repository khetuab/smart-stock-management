import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import 'auth_controller.dart';

class UserManagementController extends GetxController {
  AuthController get _auth => Get.find<AuthController>();

  static UserManagementController get to {
    if (Get.isRegistered<UserManagementController>()) return Get.find<UserManagementController>();
    return Get.put(UserManagementController(), permanent: true);
  }

  var users = <User>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var updatingUsername = ''.obs; // which row's button is mid-request, for a per-row spinner

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  List<User> get filteredUsers {
    if (searchQuery.value.trim().isEmpty) return users;
    final q = searchQuery.value.trim().toLowerCase();
    return users.where((u) =>
    u.username.toLowerCase().contains(q) || (u.phone ?? '').toLowerCase().contains(q)).toList();
  }

  int get adminCount => users.where((u) => u.role.trim().toLowerCase() == 'admin').length;

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      users.value = await _auth.getAllUsers();
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void search(String query) => searchQuery.value = query;

  Future<void> toggleAdmin(User user) async {
    final isCurrentlyAdmin = user.role.trim().toLowerCase() == 'admin';
    final newRole = isCurrentlyAdmin ? 'customer' : 'admin';

    try {
      updatingUsername.value = user.username;
      final success = await _auth.setUserRole(user.username, newRole);
      if (success) {
        final index = users.indexWhere((u) => u.username == user.username);
        if (index != -1) users[index] = user.copyWith(role: newRole);
        Get.snackbar(
          'Success',
          isCurrentlyAdmin ? '${user.username} is now a customer'.tr : '${user.username} is now an admin'.tr,
          colorText: Colors.white, backgroundColor: Colors.green, snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      updatingUsername.value = '';
    }
  }

  Future<void> refresh() => loadUsers();
}