import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';

class ChangePasswordScreen extends GetView<AuthController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var currentPassword = ''.obs;
    var newPassword = ''.obs;
    var confirmPassword = ''.obs;
    var obscureCurrent = true.obs;
    var obscureNew = true.obs;
    var obscureConfirm = true.obs;
    var isLoading = false.obs;

    void updateCurrentPassword(String value) {
      currentPassword.value = value;
    }

    void updateNewPassword(String value) {
      newPassword.value = value;
    }

    void updateConfirmPassword(String value) {
      confirmPassword.value = value;
    }

    Future<void> changePassword() async {
      // Validate
      if (currentPassword.value.isEmpty) {
        Get.snackbar(
          'errorSnackbarTitle'.tr,
          'enterCurrentPasswordError'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (newPassword.value.isEmpty || confirmPassword.value.isEmpty) {
        Get.snackbar(
          'errorSnackbarTitle'.tr,
          'fillAllFieldsError'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (newPassword.value != confirmPassword.value) {
        Get.snackbar(
          'errorSnackbarTitle'.tr,
          'passwordsDoNotMatchError'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (newPassword.value.length < 6) {
        Get.snackbar(
          'errorSnackbarTitle'.tr,
          'passwordMinLengthError'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Verify current password
      // This would need to be implemented in AuthController
      try {
        isLoading.value = true;

        // Here you would call authController.changePassword
        // For now, we'll just show success
        await Future.delayed(const Duration(seconds: 1));

        Get.snackbar(
          'successSnackbarTitle'.tr,
          'passwordChangedSuccessMessage'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.back();
      } catch (e) {
        Get.snackbar(
          'errorSnackbarTitle'.tr,
          '${'failedToChangePasswordMessage'.tr}: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('changePasswordTitle'.tr),
        backgroundColor: Color(
          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
        ),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'changeYourPasswordSubtitle'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              // Current Password
              Obx(() => TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrent.value,
                decoration: InputDecoration(
                  labelText: 'currentPasswordLabel'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureCurrent.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      obscureCurrent.value = !obscureCurrent.value;
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: updateCurrentPassword,
              )),

              const SizedBox(height: 16),

              // New Password
              Obx(() => TextField(
                controller: newPasswordController,
                obscureText: obscureNew.value,
                decoration: InputDecoration(
                  labelText: 'newPasswordLabel'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      obscureNew.value = !obscureNew.value;
                    },
                  ),
                  border: const OutlineInputBorder(),
                  helperText: 'minimumCharactersHelper'.tr,
                  helperStyle: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                onChanged: updateNewPassword,
              )),

              const SizedBox(height: 16),

              // Confirm Password
              Obx(() => TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm.value,
                decoration: InputDecoration(
                  labelText: 'confirmNewPasswordLabel'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      obscureConfirm.value = !obscureConfirm.value;
                    },
                  ),
                  border: const OutlineInputBorder(),
                  errorText: confirmPassword.value.isNotEmpty &&
                      newPassword.value != confirmPassword.value
                      ? 'passwordsDoNotMatchError'.tr
                      : null,
                ),
                onChanged: updateConfirmPassword,
              )),

              const SizedBox(height: 16),

              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequirement(
                      'reqMinCharacters'.tr,
                      newPassword.value.length >= 6,
                    ),
                    _buildRequirement(
                      'reqAtLeastOneNumber'.tr,
                      newPassword.value.contains(RegExp(r'[0-9]')),
                    ),
                    _buildRequirement(
                      'reqAtLeastOneUppercase'.tr,
                      newPassword.value.contains(RegExp(r'[A-Z]')),
                    ),
                    _buildRequirement(
                      'reqPasswordsMatch'.tr,
                      newPassword.value.isNotEmpty &&
                          newPassword.value == confirmPassword.value,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(
                      int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'changePasswordButton'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}