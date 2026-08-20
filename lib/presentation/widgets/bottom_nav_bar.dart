import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

/// Bottom navigation bar, now fully theme-driven (was already using
/// `Theme.of(context).primaryColor` for the selected item, but had
/// `Colors.grey` hardcoded for unselected items, which looked wrong in
/// dark mode — swapped for `colorScheme.onSurfaceVariant`).
///
/// Zakat is only shown when enabled in Settings (non-Muslim merchants get
/// a clean 7-item bar) and sits last in the order. Since that changes how
/// many items exist, `onTap` navigates using each item's own attached
/// route instead of a hardcoded index switch — a fixed switch would
/// silently break (tap the wrong screen) the moment Zakat's presence
/// shifts other items over by one position.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dashboardController = Get.find<DashboardController>();

    return Obx(() {
      final zakatEnabled = dashboardController.zakatEnabled.value;

      final items = <_NavItem>[
        _NavItem(Icons.dashboard_rounded, 'dashboard', '/dashboard'),
        _NavItem(Icons.inventory_2_rounded, 'products', '/products'),
        _NavItem(Icons.shopping_cart_rounded, 'sales', '/sales'),
        _NavItem(Icons.shopping_bag_rounded, 'purchases', '/purchases'),
        _NavItem(Icons.category_rounded, 'categories', '/categories'),
        _NavItem(Icons.query_stats, 'reports', '/reports'),
        _NavItem(Icons.settings_rounded, 'settings', '/settings'),
        if (zakatEnabled) _NavItem(Icons.mosque_rounded, 'zakat', '/zakat'),
      ];

      return BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: items
            .map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.labelKey.tr,
        ))
            .toList(),
        onTap: (index) => Get.offAllNamed(items[index].route),
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