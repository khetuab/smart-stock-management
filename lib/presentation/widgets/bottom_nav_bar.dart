import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../controllers/order_controller.dart';

/// Admin bottom navigation: Dashboard, Products, Orders, Media, Islamic,
/// Settings.
///
/// Design: a clean, edge-to-edge bar. The active tab expands into a soft
/// tinted pill that reveals its label next to a filled icon, while the other
/// tabs collapse to quiet outlined icons. Widths animate together so the
/// row never jumps.
class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const double _barHeight = 64;

  static final _items = <_NavItem>[
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'dashboard',
        '/dashboard'),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded,
        'products', '/products'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
        'orders', '/orders',
        showsOrderBadge: true),
    _NavItem(Icons.add_circle_outline_rounded, Icons.add_circle_rounded,
        'media', AppRoutes.createPostScreen),
    _NavItem(Icons.mosque_outlined, Icons.mosque_rounded, 'islamic',
        AppRoutes.islamicHub,
        push: true),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'settings',
        '/settings'),
  ];

  late int _selected;
  bool _busy = false;

  int _clamp(int i) => i.clamp(0, _items.length - 1);

  @override
  void initState() {
    super.initState();
    _selected = _clamp(widget.currentIndex);
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_busy && _clamp(widget.currentIndex) != _selected) {
      setState(() => _selected = _clamp(widget.currentIndex));
    }
  }

  Future<void> _onTap(int index) async {
    if (_busy || index == _selected) return;
    HapticFeedback.selectionClick();

    _busy = true;
    setState(() => _selected = index);

    // Let the pill finish most of its motion before the route changes.
    await Future.delayed(const Duration(milliseconds: 160));
    final item = _items[index];

    if (item.push) {
      // Islamic features live on their own screen, opened on top; restore
      // the active tab when the admin comes back.
      await Get.toNamed(item.route);
      if (mounted) {
        _busy = false;
        setState(() => _selected = _clamp(widget.currentIndex));
      }
    } else {
      Get.offAllNamed(item.route);
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final hasUnread = Get.find<OrderController>().hasUnreadForAdmin;

      return Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.45),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, c) {
              const hPad = 8.0;
              final n = _items.length;
              final avail = c.maxWidth - hPad * 2;

              // Collapsed tabs share the leftover space with one wide pill.
              final collapsed = math.min(46.0, (avail - 96) / (n - 1));
              final expanded = math.min(150.0, avail - (n - 1) * collapsed);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(n, (i) {
                    final item = _items[i];
                    return _NavTile(
                      item: item,
                      selected: i == _selected,
                      showBadge: item.showsOrderBadge && hasUnread,
                      collapsedWidth: collapsed,
                      expandedWidth: expanded,
                      height: _barHeight,
                      onTap: () => _onTap(i),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// One tab
// ─────────────────────────────────────────────────────────────────────────
class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool showBadge;
  final double collapsedWidth;
  final double expandedWidth;
  final double height;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.showBadge,
    required this.collapsedWidth,
    required this.expandedWidth,
    required this.height,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.selected ? 1 : 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final width =
            widget.collapsedWidth +
                (widget.expandedWidth - widget.collapsedWidth) * t;
        final iconColor =
        Color.lerp(scheme.onSurfaceVariant, scheme.primary, t)!;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.93 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: SizedBox(
              width: width,
              height: widget.height,
              child: Center(
                child: Container(
                  width: width,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.13 * t),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // icon (outlined → filled) + optional badge
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                      opacity: anim,
                                      child: ScaleTransition(
                                        scale: Tween<double>(begin: 0.85, end: 1)
                                            .animate(anim),
                                        child: child,
                                      ),
                                    ),
                                child: Icon(
                                  widget.selected
                                      ? widget.item.selectedIcon
                                      : widget.item.icon,
                                  key: ValueKey(widget.selected),
                                  size: 24,
                                  color: iconColor,
                                ),
                              ),
                              if (widget.showBadge)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: _Badge(color: scheme.error),
                                ),
                            ],
                          ),
                        ),

                        // label reveals smoothly beside the icon
                        Flexible(
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: Opacity(
                                opacity: Curves.easeIn.transform(t),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    widget.item.labelKey.tr,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Unread badge (pops in, ringed with the bar colour)
// ─────────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final Color color;
  const _Badge({required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).cardColor, width: 1.6),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  final String route;
  final bool showsOrderBadge;
  final bool push;
  const _NavItem(
      this.icon,
      this.selectedIcon,
      this.labelKey,
      this.route, {
        this.showsOrderBadge = false,
        this.push = false,
      });
}