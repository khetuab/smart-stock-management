import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/notification_controller.dart';
import '../../app/routes/app_routes.dart';

/// Reduced bottom navigation bar with 5 items for better UX.
/// Items: Dashboard, Products, Orders, Islamic, Settings
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // ignore: unused_local_variable
    final dashboardController = Get.find<DashboardController>();

    return Obx(() {
      final hasUnread = Get.find<NotificationController>().hasUnread;

      final items = <_NavItem>[
        _NavItem(Icons.dashboard_rounded, 'dashboard', '/dashboard'),
        _NavItem(Icons.inventory_2_rounded, 'products', '/products'),
        _NavItem(Icons.add, 'media', AppRoutes.createPostScreen),
        _NavItem(Icons.mosque_rounded, 'islamic', AppRoutes.islamicHub),
        _NavItem(Icons.settings_rounded, 'settings', '/settings'),
      ];

      return BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: items.map((item) {
          bool showBadge = item.route == '/orders' && hasUnread;
          return BottomNavigationBarItem(
            icon: showBadge
                ? Stack(
              children: [
                Icon(item.icon),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                    child: const Text(
                      '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ],
            )
                : Icon(item.icon),
            label: item.labelKey.tr,
          );
        }).toList(),
        onTap: (index) {
          if (index == 3) {
            // Islamic features now live on their own dedicated screen.
            Get.toNamed(AppRoutes.islamicHub);
          } else {
            Get.offAllNamed(items[index].route);
          }
        },
      );
    });
  }
}

class _NavItem {
  final IconData icon;
  final String labelKey;
  final String route;
  const _NavItem(this.icon, this.labelKey, this.route);
}