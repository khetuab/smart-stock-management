import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../controllers/notification_controller.dart';

/// Bottom nav for the customer shell: Home (shop), My Orders, Islamic
/// tools, Settings. Deliberately separate from the admin BottomNavBar,
/// which links to Dashboard/Products(with edit rights)/Reports-adjacent
/// screens a customer must never reach.
class CustomerBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final hasUnread = Get.find<NotificationController>().hasUnread;

      final items = <_NavItem>[
        _NavItem(Icons.storefront_rounded, 'browseShop', AppRoutes.customerHome),
        _NavItem(Icons.shopping_bag_outlined, 'products', AppRoutes.allProducts),
        _NavItem(Icons.play_arrow_rounded, 'media', AppRoutes.mediaFeed),
        _NavItem(Icons.mosque_rounded, 'islamic', AppRoutes.islamicHubc),
        _NavItem(Icons.settings_rounded, 'settings', AppRoutes.customerSettings),
      ];

      return BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: items.map((item) {
          final showBadge = item.route == AppRoutes.orders && hasUnread;
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
                    decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                  ),
                ),
              ],
            )
                : Icon(item.icon),
            label: item.labelKey.tr,
          );
        }).toList(),
        onTap: (index) {
          final route = items[index].route;
          if (route == AppRoutes.customerHome) {
            Get.offAllNamed(route);
          } else {
            Get.toNamed(route);
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