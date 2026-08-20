import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/services/cloudinary_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  Color _parseColor(String hexColor, {Color fallback = const Color(0xFF2563EB)}) {
    try {
      final cleanHex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final themeController = Get.find<ThemeController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final primaryColor = _parseColor(dashboardController.themeColor.value);

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // --- Custom SliverAppBar matching Dashboard ---
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              snap: false,
              elevation: 0,
              scrolledUnderElevation: 4,
              surfaceTintColor: scheme.surface,
              backgroundColor: scheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  'Settings'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Vector Drawn Mesh Background
                    CustomPaint(
                      painter: _StoreMeshHeaderPainter(
                        primaryColor: scheme.primary,
                        secondaryColor: scheme.tertiary,
                        isDark: isDark,
                      ),
                    ),
                    // Soft Vignette Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // Subtitle Details
                    Positioned(
                      left: 20,
                      bottom: 48,
                      right: 20,
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Preferences & App Configurations'.tr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Scrollable Settings Content ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile Header
                    _buildHeaderCard(context, primaryColor, scheme, isDark)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 24),

                    // 2. Store Configuration
                    _buildSectionGroup(
                      context,
                      title: 'STORE CONFIGURATION'.tr,
                      scheme: scheme,
                      isDark: isDark,
                      items: [
                        _buildSettingTile(
                          context,
                          icon: Icons.storefront_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Store Name'.tr,
                          subtitle: controller.storeName.value.isEmpty
                              ? 'Not set'.tr
                              : controller.storeName.value,
                          onTap: () => _showEditBottomSheet(
                            context,
                            'Store Name'.tr,
                            controller.storeName.value,
                                (val) => controller.updateStoreInfo(storeName: val),
                          ),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.person_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Owner Name'.tr,
                          subtitle: controller.ownerName.value.isEmpty
                              ? 'Not set'.tr
                              : controller.ownerName.value,
                          onTap: () => _showEditBottomSheet(
                            context,
                            'Owner Name'.tr,
                            controller.ownerName.value,
                                (val) => controller.updateStoreInfo(ownerName: val),
                          ),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.currency_exchange_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'Currency'.tr,
                          subtitle: controller.currency.value,
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Language'.tr,
                          subtitle: controller.language.value.tr,
                          onTap: () => _showLanguagePicker(context),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms, duration: 500.ms),

                    const SizedBox(height: 20),

                    // 3. Customization & Theme
                    _buildSectionGroup(
                      context,
                      title: 'CUSTOMIZATION'.tr,
                      scheme: scheme,
                      isDark: isDark,
                      items: [
                        _buildSwitchTile(
                          context,
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Dark Theme'.tr,
                          subtitle: themeController.themeMode.value == ThemeMode.dark
                              ? 'Dark mode active'.tr
                              : 'Light mode active'.tr,
                          value: themeController.themeMode.value == ThemeMode.dark,
                          primaryColor: primaryColor,
                          onChanged: (val) {
                            themeController.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.palette_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: 'Theme Color'.tr,
                          subtitle: 'Personalize app accent color'.tr,
                          trailing: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                          onTap: () => _showColorPickerBottomSheet(context),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                    const SizedBox(height: 20),

                    // 4. Business Options
                    _buildSectionGroup(
                      context,
                      title: 'BUSINESS OPTIONS'.tr,
                      scheme: scheme,
                      isDark: isDark,
                      items: [
                        _buildSwitchTile(
                          context,
                          icon: Icons.calculate_rounded,
                          iconColor: const Color(0xFF059669),
                          title: 'Enable Zakat Calculator'.tr,
                          subtitle: 'Automatic zakat estimation on inventory'.tr,
                          value: controller.zakatEnabled.value,
                          primaryColor: primaryColor,
                          onChanged: controller.toggleZakat,
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                    const SizedBox(height: 20),

                    // 5. Security & Data
                    _buildSectionGroup(
                      context,
                      title: 'SECURITY & DATA'.tr,
                      scheme: scheme,
                      isDark: isDark,
                      items: [
                        _buildSettingTile(
                          context,
                          icon: Icons.lock_rounded,
                          iconColor: const Color(0xFFD97706),
                          title: 'Change Password'.tr,
                          subtitle: 'Update your account credentials'.tr,
                          onTap: () => _showPasswordBottomSheet(context),
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.cloud_upload_rounded,
                          iconColor: const Color(0xFF2563EB),
                          title: 'Backup Data'.tr,
                          subtitle: 'Save a backup copy to local/cloud storage'.tr,
                          onTap: controller.performBackup,
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.cloud_download_rounded,
                          iconColor: const Color(0xFF0891B2),
                          title: 'Restore Data'.tr,
                          subtitle: 'Restore database from previous snapshot'.tr,
                          onTap: (){controller.restoreBackup(context);},
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                    const SizedBox(height: 20),

                    // 6. Danger Zone / Account
                    _buildSectionGroup(
                      context,
                      title: 'ACCOUNT ACTIONS'.tr,
                      scheme: scheme,
                      isDark: isDark,
                      items: [
                        _buildSettingTile(
                          context,
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFEF4444),
                          title: 'Logout'.tr,
                          titleColor: const Color(0xFFEF4444),
                          hideChevron: true,
                          onTap: controller.logout,
                        ),
                        _buildSettingTile(
                          context,
                          icon: Icons.restart_alt_rounded,
                          iconColor: const Color(0xFFDC2626),
                          title: 'Reset Application'.tr,
                          subtitle: 'Clear all local data and preferences'.tr,
                          titleColor: const Color(0xFFDC2626),
                          hideChevron: true,
                          onTap: () => _showResetPasswordDialog(context),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms, duration: 300.ms),

                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        'Smart Stock • Version 1.0.0'.tr,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 6),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final RxBool isObscured = true.obs;
    final RxString errorMessage = ''.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Text(
              'Confirm Reset'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will erase all local data. Please enter your password to proceed:'.tr,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Obx(
                  () => TextField(
                controller: passwordController,
                obscureText: isObscured.value,
                decoration: InputDecoration(
                  labelText: 'Enter Password'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscured.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => isObscured.toggle(),
                  ),
                  errorText: errorMessage.value.isEmpty ? null : errorMessage.value,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final enteredPassword = passwordController.text.trim();

              if (enteredPassword.isEmpty) {
                errorMessage.value = 'Password required'.tr;
                return;
              }

              // Verify password using controller logic
              bool isValid = await controller.verifyUserPassword(enteredPassword);

              if (isValid) {
                Get.back(); // Close dialog
                controller.resetApp(); // Execute reset
              } else {
                errorMessage.value = 'Incorrect password'.tr;
              }
            },
            child: Text('Reset App'.tr),
          ),
        ],
      ),
    );
  }
  // --- UI BUILDING BLOCKS ---

  Widget _buildHeaderCard(
      BuildContext context, Color primaryColor, ColorScheme scheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2B33) : const Color(0xFFE8ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showLogoPicker(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.12),
                    border: Border.all(color: primaryColor.withOpacity(0.2), width: 2.5),
                    image: controller.storeLogo.value.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(controller.storeLogo.value),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: controller.storeLogo.value.isEmpty
                      ? Icon(Icons.storefront_rounded, size: 36, color: primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.storeName.value.isEmpty ? 'My Store'.tr : controller.storeName.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'Owner'.tr}: ${controller.ownerName.value.isEmpty ? 'Not specified'.tr : controller.ownerName.value}',
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGroup(
      BuildContext context, {
        required String title,
        required List<Widget> items,
        required ColorScheme scheme,
        required bool isDark,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2B33) : const Color(0xFFE8ECF2),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  items[index],
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 64,
                      color: isDark ? const Color(0xFF2A2B33) : const Color(0xFFE8ECF2),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        String? subtitle,
        Widget? trailing,
        Color? titleColor,
        bool hideChevron = false,
        required VoidCallback onTap,
      }) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && !hideChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurface.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required bool value,
        required Color primaryColor,
        required Function(bool) onChanged,
      }) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- MODERN BOTTOM SHEETS ---

  void _showEditBottomSheet(
      BuildContext context,
      String title,
      String currentValue,
      Function(String) onSave,
      ) {
    final textController = TextEditingController(text: currentValue);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'Edit'.tr} $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: title,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    onSave(textController.text.trim());
                    Get.back();
                  }
                },
                child: Text('Save Changes'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    final currencies = ['ETB', 'USD', 'EUR', 'GBP', 'AED'];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Currency'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...currencies.map((currency) {
              final isSelected = controller.currency.value == currency;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(currency, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24) : null,
                onTap: () {
                  controller.updateStoreInfo(currency: currency);
                  Get.back();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final languages = ['English', 'Amharic', 'Arabic'];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...languages.map((language) {
              final isSelected = controller.language.value == language;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(language.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24) : null,
                onTap: () {
                  controller.changeLanguage(language);
                  Get.back();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showColorPickerBottomSheet(BuildContext context) {
    final colors = [
      '#2563EB', '#10B981', '#F59E0B', '#8B5CF6',
      '#EC4899', '#06B6D4', '#EF4444', '#84CC16',
      '#6366F1', '#14B8A6', '#F97316', '#64748B',
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Theme Accent'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((colorHex) {
                final color = _parseColor(colorHex);
                final isSelected = controller.themeColor.value == colorHex;

                return GestureDetector(
                  onTap: () {
                    controller.changeThemeColor(colorHex);
                    Get.back();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 26) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLogoPicker(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update Store Logo'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Get.back();
                      _pickImage(ImageSource.gallery, context);
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text('Gallery'.tr, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Get.back();
                      _pickImage(ImageSource.camera, context);
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text('Camera'.tr, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            if (controller.storeLogo.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Get.back();
                  controller.changeLogo('');
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                label: Text('Remove current logo'.tr, style: const TextStyle(color: Colors.red, fontSize: 15)),
              )
            ]
          ],
        ),
      ),
    );
  }

  void _showPasswordBottomSheet(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Change Password'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) => controller.currentPassword.value = val,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) => controller.newPassword.value = val,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password'.tr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) => controller.confirmNewPassword.value = val,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    Get.back();
                    await controller.changePassword();
                  },
                  child: Text('Update Password'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              )
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);

    if (image != null) {
      try {
        controller.isLoading.value = true;
        final cloudinary = CloudinaryService();

        // Pass the XFile directly using uploadXFile
        final imageUrl = await cloudinary.uploadXFile(
          xFile: image,
          folder: 'store_logos',
          isPublic: true,
        );

        if (imageUrl != null) {
          await controller.changeLogo(imageUrl);
        }
      } finally {
        controller.isLoading.value = false;
      }
    }
  }
}

class _StoreMeshHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _StoreMeshHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final meshGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
        HSLColor.fromColor(secondaryColor).withLightness(isDark ? 0.14 : 0.30).toColor(),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = meshGradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.88, height * 0.10), 130, Colors.white, 0.14, 70);
    glassOrb(Offset(width * 0.15, height * 0.85), 100, secondaryColor, 0.30, 60);
    glassOrb(Offset(width * 0.55, height * 0.05), 70, Colors.white, 0.10, 40);

    final sheenPath = Path()
      ..moveTo(width * 0.35, -20)
      ..lineTo(width * 0.55, -20)
      ..lineTo(width * 0.05, height + 20)
      ..lineTo(width * -0.15, height + 20)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect),
    );

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34, ringPaint);
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34 * 1.5, ringPaint..color = Colors.white.withOpacity(0.08));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _StoreMeshHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}