import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../../widgets/mejlis_kit.dart';
import '../auth/customer_welcome_screen.dart';

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
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 5),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 235,
            floating: false,
            pinned: true,
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                      image: dashboard.storeLogo.value.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(dashboard.storeLogo.value),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: dashboard.storeLogo.value.isEmpty
                        ? const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                    )
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
                  const MejlisHeaderBackground(),
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
                    child: Obx(
                          () => Row(
                        children: [
                          const _ProfileAvatar(size: 52),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.isLoggedIn.value
                                      ? auth.username.value
                                      : 'Not logged in'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 6,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // _SectionHeader(title: 'Your Profile'.tr, icon: Icons.person_rounded, color: scheme.primary),
                // const SizedBox(height: 10),
                // SectionCard(
                //   padding: EdgeInsets.zero,
                //   child: _SettingTile(
                //     icon: Icons.badge_outlined,
                //     iconColor: scheme.primary,
                //     title: 'Edit Profile'.tr,
                //     subtitle: 'Update your phone number'.tr,
                //     onTap: () => _showEditProfileSheet(context, auth),
                //   ),
                // ),

                const SizedBox(height: 24),
                _SectionHeader(title: 'Appearance'.tr, icon: Icons.palette_outlined, color: const Color(0xFF6366F1)),
                const SizedBox(height: 10),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Obx(
                          () => SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        secondary: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        title: Text(
                          'Dark Mode'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        value: themeController.themeMode.value == ThemeMode.dark,
                        onChanged: (value) => themeController.setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ),
                    ),
                  ),
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
                      const Divider(height: 20),
                      _LanguageOption(label: 'Afaan Oromoo', locale: const Locale('om', 'ET')),
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
                const SizedBox(height: 24),
                _SectionHeader(title: 'Support'.tr, icon: Icons.headset_mic_outlined, color: const Color(0xFFC9A227)),
                const SizedBox(height: 10),
                SectionCard(
                  padding: EdgeInsets.zero,
                  child: _SettingTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF0B6E4F),
                    title: 'contactUs'.tr,
                    subtitle: 'callBranch'.tr,
                    onTap: () => Get.toNamed(AppRoutes.contactUs),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Developer Contact'.tr,
                  icon: Icons.code_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(height: 10),
                const _DeveloperContactCard(),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Session'.tr, icon: Icons.logout_rounded, color: Colors.red),
                const SizedBox(height: 10),
                Obx(() => SectionCard(
                  padding: EdgeInsets.zero,
                  child: auth.isLoggedIn.value
                      ? _SettingTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: 'Log Out'.tr,
                    hideChevron: true,
                    onTap: () => _confirmEndSession(context, auth),
                  )
                      : _SettingTile(
                    icon: Icons.login_rounded,
                    iconColor: scheme.primary,
                    title: 'Log In / Create Account'.tr,
                    hideChevron: true,
                    onTap: () => Get.to(() => const CustomerWelcomeScreen()),
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
        title: Text('Log Out'.tr),
        content: Text("You'll need to log in again to place new orders.".tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            onPressed: () {
              Get.back();
              auth.logoutCustomer();
            },
            child: Text('Log Out'.tr),
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
/// Illustrated profile placeholder: white figure on a blue gradient,
/// inside a glassy white ring.
class _ProfileAvatar extends StatelessWidget {
  final double size;
  const _ProfileAvatar({this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: _ProfileAvatarPainter(),
          size: Size.square(size - 5),
        ),
      ),
    );
  }
}

class _ProfileAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Blue background gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF161F2B), Color(0xFF13182C), Color(0xFF010A29)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Soft light bloom, top-left
    canvas.drawCircle(
      Offset(w * 0.25, h * 0.15),
      w * 0.42,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.16),
    );

    // Shoulders / torso
    final body = Path()
      ..moveTo(w * 0.12, h)
      ..cubicTo(w * 0.12, h * 0.74, w * 0.28, h * 0.63, w * 0.5, h * 0.63)
      ..cubicTo(w * 0.72, h * 0.63, w * 0.88, h * 0.74, w * 0.88, h)
      ..close();

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFDBEAFE)],
        ).createShader(rect),
    );

    // Head shadow cast onto the shoulders
    final headCenter = Offset(w * 0.5, h * 0.37);
    final headRadius = w * 0.18;
    canvas.save();
    canvas.clipPath(body);
    canvas.drawCircle(
      headCenter.translate(0, h * 0.09),
      headRadius * 1.1,
      Paint()
        ..color = const Color(0xFF1E2747).withOpacity(0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
    );
    canvas.restore();

    // Head
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE0EDFF)],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Developer / company contact card (Tixolve). Tap any row to copy.
class _DeveloperContactCard extends StatelessWidget {
  const _DeveloperContactCard();

  static const _phone = '0906464607';
  static const _telegram = '@Tixolve_admin';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.business_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tixolve',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Developed by Tixolve'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          const _CopyableContactRow(
            icon: Icons.phone_rounded,
            color: Color(0xFF10B981),
            label: 'Phone',
            value: _phone,
          ),
          const Divider(height: 20),
          const _CopyableContactRow(
            icon: Icons.send_rounded,
            color: Color(0xFF229ED9),
            label: 'Telegram',
            value: _telegram,
          ),
        ],
      ),
    );
  }
}

class _CopyableContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _CopyableContactRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: value));
    Get.closeAllSnackbars();
    Get.snackbar(
      'Copied'.tr,
      '$value ${'copied to clipboard'.tr}',
      colorText: Colors.white,
      backgroundColor: color,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _copy,
      onLongPress: _copy,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 20,
              color: scheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}