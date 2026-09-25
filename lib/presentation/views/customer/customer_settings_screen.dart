import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';

/// Settings screen scoped to what a customer actually needs: their own
/// profile, personal appearance/language preferences, a read-only
/// "about this shop" card, and session controls.
///
/// Deliberately does NOT depend on SettingsController — the admin
/// settings screen uses it to change STORE-WIDE branding (the theme
/// color picker previously here called `changeThemeColor()`, which
/// rewrites the shared settings for every user of the app). A customer
/// screen has no business touching that; dark mode below is a personal,
/// per-device preference instead.
class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Get.find<AuthController>();
    final dashboard = Get.find<DashboardController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 4),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            floating: false,
            elevation: 0,
            scrolledUnderElevation: 4,
            surfaceTintColor: scheme.surface,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Obx(
                      () => Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                      image: dashboard.storeLogo.value.isNotEmpty
                          ? DecorationImage(image: NetworkImage(dashboard.storeLogo.value), fit: BoxFit.cover)
                          : null,
                    ),
                    child: dashboard.storeLogo.value.isEmpty
                        ? const Icon(Icons.storefront_rounded, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'settings'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _SettingsHeaderPainter(
                      primaryColor: scheme.primary,
                      secondaryColor: scheme.tertiary,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.transparent,
                          Colors.black.withOpacity(0.35),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 50,
                    child: Obx(() => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.15),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.username.value.isEmpty ? 'Guest'.tr : auth.username.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  shadows: [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 1))],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.phone.value.isEmpty ? 'No phone on file'.tr : auth.phone.value,
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: 'Your Profile'.tr, icon: Icons.person_rounded, color: scheme.primary),
                const SizedBox(height: 10),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: _SettingTile(
                    icon: Icons.badge_outlined,
                    iconColor: scheme.primary,
                    title: 'Edit Profile'.tr,
                    subtitle: 'Update your phone number'.tr,
                    onTap: () => _showEditProfileSheet(context, auth),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'Appearance'.tr, icon: Icons.palette_outlined, color: const Color(0xFF6366F1)),
                const SizedBox(height: 10),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: Obx(() => SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dark_mode_rounded, color: Color(0xFF6366F1)),
                    ),
                    title: Text('Dark Mode'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    value: themeController.themeMode.value == ThemeMode.dark,
                    onChanged: (value) => themeController.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                  )),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'Language'.tr, icon: Icons.translate_rounded, color: const Color(0xFF06B6D4)),
                const SizedBox(height: 10),
                SectionCard(
                  child: Column(
                    children: [
                      _LanguageOption(label: 'English', locale: const Locale('en', 'US')),
                      const Divider(height: 20),
                      _LanguageOption(label: 'አማርኛ', locale: const Locale('am', 'ET')),
                      const Divider(height: 20),
                      _LanguageOption(label: 'العربية', locale: const Locale('ar', 'SA')),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'About This Shop'.tr, icon: Icons.storefront_outlined, color: const Color(0xFF10B981)),
                const SizedBox(height: 10),
                Obx(() => SectionCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          image: dashboard.storeLogo.value.isNotEmpty
                              ? DecorationImage(image: NetworkImage(dashboard.storeLogo.value), fit: BoxFit.cover)
                              : null,
                        ),
                        child: dashboard.storeLogo.value.isEmpty
                            ? Icon(Icons.storefront_rounded, color: scheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dashboard.storeName.value.isEmpty ? 'Smart Stock' : dashboard.storeName.value,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: scheme.onSurface),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${'Currency'.tr}: ${dashboard.currency.value}',
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),


              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, AuthController auth) {
    final phoneCtrl = TextEditingController(text: auth.phone.value);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: auth.username.value),
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Username'.tr,
                helperText: 'Username cannot be changed'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone'.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => FilledButton(
                onPressed: auth.isLoading.value
                    ? null
                    : () async {
                  final success = await auth.updatePhone(phoneCtrl.text);
                  Get.back();
                  Get.snackbar(
                    success ? 'Saved' : 'Error',
                    success ? 'Your phone number was updated.'.tr : 'Could not update your phone number.'.tr,
                    colorText: Colors.white,
                    backgroundColor: success ? Colors.green : Colors.red,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: auth.isLoading.value
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmEndSession(BuildContext context, AuthController auth) {
    Get.dialog(
      AlertDialog(
        title: Text('End Session'.tr),
        content: Text("You'll need to log in again to place new orders.".tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            onPressed: () {
              Get.back();
              auth.logoutGuest();
            },
            child: Text('End Session'.tr),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface)),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool hideChevron;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.hideChevron = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: titleColor ?? scheme.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            if (!hideChevron) Icon(Icons.chevron_right_rounded, size: 22, color: scheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final Locale locale;

  const _LanguageOption({required this.label, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isSelected = Get.locale?.languageCode == locale.languageCode;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Get.updateLocale(locale),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

/// Same glass-mesh visual language as the rest of the app's headers.
class _SettingsHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _SettingsHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }

    glassOrb(Offset(width * 0.85, height * 0.15), 90, Colors.white, 0.15, 50);
    glassOrb(Offset(width * 0.12, height * 0.8), 70, secondaryColor, 0.28, 45);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
          stops: const [0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SettingsHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
}