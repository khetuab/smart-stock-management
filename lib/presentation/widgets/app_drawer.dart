import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoute = Get.currentRoute;

    return Drawer(
      width: 288,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      child: Obx(
            () => Column(
          children: [
            // --- Painted Glass Header ---
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
                    child: CustomPaint(
                      painter: _DrawerHeaderPainter(
                        primaryColor: scheme.primary,
                        secondaryColor: scheme.tertiary,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white24,
                            backgroundImage: dashboardController.storeLogo.value.isNotEmpty
                                ? NetworkImage(dashboardController.storeLogo.value)
                                : null,
                            child: dashboardController.storeLogo.value.isEmpty
                                ? const Icon(Icons.storefront_rounded, size: 26, color: Colors.white)
                                : null,
                          ),
                        ).animate().scale(delay: 80.ms, duration: 350.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 12),
                        Text(
                          dashboardController.storeName.value.isEmpty
                              ? 'Smart Stock'
                              : dashboardController.storeName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 300.ms).slideX(begin: -0.08, end: 0),
                        const SizedBox(height: 2),
                        Text(
                          authController.username.value.isEmpty
                              ? 'ownerName'.tr
                              : authController.username.value,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Nav items with staggered entrance ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                children: [
                  ..._buildItems(context, currentRoute, dashboardController),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'settings'.tr,
                    isActive: currentRoute == '/settings',
                    onTap: () => Get.offAllNamed('/settings'),
                    index: 9,
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'logout'.tr,
                    isActive: false,
                    onTap: () => Get.find<AuthController>().logout(),
                    color: scheme.error,
                    index: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItems(
      BuildContext context, String currentRoute, DashboardController dashboardController) {
    final items = <_NavItemData>[
      _NavItemData(Icons.dashboard_rounded, 'dashboard'.tr, '/dashboard'),
      _NavItemData(Icons.inventory_2_rounded, 'products'.tr, '/products'),
      _NavItemData(Icons.shopping_cart_rounded, 'sales'.tr, '/sales'),
      _NavItemData(Icons.shopping_bag_rounded, 'purchases'.tr, '/purchases'),
      _NavItemData(Icons.receipt_long_rounded, 'saleHistory'.tr, '/sale-history'),
      _NavItemData(Icons.account_balance_wallet_rounded, 'debtsAndCredits'.tr, '/debts'),
      _NavItemData(Icons.bar_chart_rounded, 'reports'.tr, '/reports'),
      if (dashboardController.zakatEnabled.value)
        _NavItemData(Icons.mosque_rounded, 'zakat'.tr, '/zakat'),
      _NavItemData(Icons.warning_amber_rounded, 'lowStock'.tr, '/low-stock'),
    ];

    return List.generate(items.length, (index) {
      final item = items[index];
      return _DrawerItem(
        icon: item.icon,
        title: item.title,
        isActive: currentRoute == item.route,
        onTap: () {
          Get.back(); // close drawer first for a snappier feel
          if (item.route == '/sale-history' ||
              item.route == '/low-stock' ||
              item.route == '/debts') {
            Get.toNamed(item.route);
          } else {
            Get.offAllNamed(item.route);
          }
        },
        index: index,
      );
    });
  }
}

class _NavItemData {
  final IconData icon;
  final String title;
  final String route;
  _NavItemData(this.icon, this.title, this.route);
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;
  final Color? color;
  final int index;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.index,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? (isActive ? scheme.primary : scheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? scheme.primary.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 21, color: tint),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color ?? (isActive ? scheme.primary : scheme.onSurface),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms, duration: 260.ms).slideX(begin: -0.12, end: 0, curve: Curves.easeOut);
  }
}

/// Same glass-mesh visual language as your Dashboard/Debts/Purchase headers,
/// scaled down for the drawer's compact header area.
class _DrawerHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _DrawerHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

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
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.85, height * 0.15), 80, Colors.white, 0.16, 45);
    glassOrb(Offset(width * 0.1, height * 0.75), 60, secondaryColor, 0.30, 40);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(width * 0.82, height * 0.25), 26, ringPaint);
    canvas.drawCircle(Offset(width * 0.82, height * 0.25), 38, ringPaint..color = Colors.white.withOpacity(0.07));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.30)],
          stops: const [0.4, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _DrawerHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
          oldDelegate.secondaryColor != secondaryColor ||
          oldDelegate.isDark != isDark;
}