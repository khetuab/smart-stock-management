import 'package:flutter/material.dart';
import 'islamic_header_painter.dart';

/// Shared SliverAppBar for every Islamic feature screen — same painted
/// header pattern as the rest of the app, so these read as part of Smart
/// Shop rather than a separate module.
class IslamicSliverAppBar extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final List<Widget>? actions;
  final double expandedHeight;

  const IslamicSliverAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.actions,
    this.expandedHeight = 168,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 4,
      surfaceTintColor: scheme.surface,
      backgroundColor: scheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
        title: Text(
          title,
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
              painter: IslamicHeaderPainter(
                primaryColor: scheme.primary,
                secondaryColor: scheme.tertiary,
                isDark: isDark,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 44,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  if (trailing != null) ...[const Spacer(), trailing!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}