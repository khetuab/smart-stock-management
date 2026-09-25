import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/widgets/customer_bottom_nar_bar.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/islamic_sliver_appbar.dart';

/// Single home for every Islamic feature — replaces the old bottom sheet.
/// Reuses the same painted-header language (IslamicSliverAppBar +
/// IslamicHeaderPainter) as Qibla/Quran so it reads as one cohesive module.
class IslamicHubScreenc extends GetView<IslamicController> {
  const IslamicHubScreenc({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          IslamicSliverAppBar(
            title: 'islamicCenter'.tr,
            icon: Icons.mosque_rounded,
            expandedHeight: 200,
            trailing: Obx(
                  () => Text(
                controller.hijriDate.value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrayerTimesRow(scheme: scheme).animate().fadeIn(duration: 400.ms).slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'explore'.tr,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      _FeatureCard(
                        icon: Icons.menu_book_rounded,
                        label: 'quran'.tr,
                        subtitle: 'readMushaf'.tr,
                        color: const Color(0xFF2E7D32),
                        onTap: () => Get.toNamed('/quran'),
                        delayMs: 0,
                      ),
                      _FeatureCard(
                        icon: Icons.explore_rounded,
                        label: 'qibla'.tr,
                        subtitle: 'findDirection'.tr,
                        color: const Color(0xFF00695C),
                        onTap: () => Get.toNamed('/qibla'),
                        delayMs: 60,
                      ),
                      _FeatureCard(
                        icon: Icons.access_time_filled_rounded,
                        label: 'prayerTimes'.tr,
                        subtitle: 'todaysSchedule'.tr,
                        color: const Color(0xFF1565C0),
                        onTap: () => Get.toNamed('/prayer-times'),
                        delayMs: 120,
                      ),
                      _FeatureCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'tasbih'.tr,
                        subtitle: 'digitalCounter'.tr,
                        color: const Color(0xFF6A1B9A),
                        onTap: () => Get.toNamed('/tasbih'),
                        delayMs: 180,
                      ),
                      _FeatureCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'hijriCalendar'.tr,
                        subtitle: 'convertDates'.tr,
                        color: const Color(0xFFAD6800),
                        onTap: () => Get.toNamed('/hijri-calendar'),
                        delayMs: 240,
                      ),

                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 3),
    );
  }
}

/// Shows all five daily prayers in one row (Sunrise excluded — it's not
/// a prayer), with the upcoming one circled and gently pulsing.
class _PrayerTimesRow extends GetView<IslamicController> {
  final ColorScheme scheme;
  const _PrayerTimesRow({required this.scheme});

  static const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _icons = [
    Icons.wb_twilight_rounded,
    Icons.wb_sunny_rounded,
    Icons.wb_sunny_outlined,
    Icons.wb_twilight_rounded,
    Icons.nights_stay_rounded,
  ];

  String? _nextPrayerName(Map<String, String> timings) {
    if (timings.isEmpty) return null;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    String? next;
    int bestDiff = 24 * 60;
    for (final name in _prayers) {
      final raw = timings[name];
      if (raw == null) continue;
      final parts = raw.split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      var diff = (h * 60 + m) - nowMinutes;
      if (diff < 0) diff += 24 * 60;
      if (diff < bestDiff) {
        bestDiff = diff;
        next = name;
      }
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _shell(
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
        );
      }

      if (controller.prayerTimes.isEmpty) {
        return _shell(
          child: Row(
            children: [
              Icon(Icons.location_off_rounded, color: scheme.onPrimary.withOpacity(0.85)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.errorMessage.value.isNotEmpty
                      ? controller.errorMessage.value
                      : 'prayerTimesUnavailable'.tr,
                  style: TextStyle(color: scheme.onPrimary.withOpacity(0.9), fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: controller.fetchPrayerTimes,
                child: Text('retry'.tr, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }

      final nextName = _nextPrayerName(controller.prayerTimes);

      return _shell(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_prayers.length, (i) {
            final name = _prayers[i];
            final time = controller.prayerTimes[name] ?? '--:--';
            return Expanded(
              child: _PrayerSlot(
                icon: _icons[i],
                label: name.tr,
                time: time,
                isNext: name == nextName,
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _shell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: scheme.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

class _PrayerSlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isNext;

  const _PrayerSlot({
    required this.icon,
    required this.label,
    required this.time,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isNext ? Colors.white : Colors.white.withOpacity(0.14),
            border: isNext ? Border.all(color: Colors.white, width: 2.5) : null,
            boxShadow: isNext
                ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isNext ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(isNext ? 1 : 0.75),
            fontSize: 11,
            fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: TextStyle(
            color: Colors.white.withOpacity(isNext ? 1 : 0.7),
            fontSize: 12,
            fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );

    if (!isNext) return content;

    return content
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int delayMs;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(isDark ? 0.35 : 0.22), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -14,
                child: Opacity(
                  opacity: isDark ? 0.10 : 0.07,
                  child: CustomPaint(
                    size: const Size(90, 90),
                    painter: _IslamicStarPainter(color: color),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipPath(
                      clipper: _ArchClipper(),
                      child: Container(
                        width: 48,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withOpacity(isDark ? 0.30 : 0.18),
                              color.withOpacity(isDark ? 0.14 : 0.08),
                            ],
                          ),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 350.ms)
        .slideY(begin: 0.12, end: 0, delay: Duration(milliseconds: delayMs), duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

/// Flat-bottomed, rounded-pointed arch — echoes a mosque mihrab niche —
/// used as the icon housing shape.
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.42)
      ..quadraticBezierTo(0, 0, w / 2, 0)
      ..quadraticBezierTo(w, 0, w, h * 0.42)
      ..lineTo(w, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Faint 8-point Islamic star (khatam) drawn as two overlapping squares —
/// a background watermark, not a focal element.
///
class _IslamicStarPainter extends CustomPainter {
  final Color color;
  const _IslamicStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    // 0977988078 - 
    // 0975806497
    Path star(double rotation) {
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = rotation + (pi / 4) * i;
        final point = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      path.close();
      return path;
    }

    canvas.drawPath(star(0), paint);
    canvas.drawPath(star(pi / 8), paint);
  }

  @override
  bool shouldRepaint(covariant _IslamicStarPainter oldDelegate) => oldDelegate.color != color;
}