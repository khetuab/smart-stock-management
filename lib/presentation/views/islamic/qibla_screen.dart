
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../app/themes/app_theme.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/mejlis_kit.dart';

// ═══════════════════════════════════════════════════════════════════════
// PREMIUM QIBLA SCREEN
// ═══════════════════════════════════════════════════════════════════════

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  late final IslamicController controller;

  @override
  void initState() {
    super.initState();

    controller = Get.find<IslamicController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.startQiblaCompass();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: scheme.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'Refresh compass',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  controller.startQiblaCompass();
                },
                icon: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(
                left: 56,
                bottom: 14,
              ),
              title: Text(
                'qiblaDirection'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: const MejlisHeaderBackground(
                showSkyline: false,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Obx(() {
                final heading = controller.compassHeading.value;
                final bearing = controller.qiblaBearing.value;

                final needleAngle =
                    (bearing - heading + 360) % 360;

                return Column(
                  children: [
                    // ── Intro ──
                    _intro(scheme)
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: 26),

                    // ── Compass illustration ──
                    _compassHero(
                      scheme: scheme,
                      isDark: isDark,
                      heading: heading,
                      bearing: bearing,
                      needleAngle: needleAngle,
                    ),

                    const SizedBox(height: 25),

                    // ── Bearing information ──
                    _bearingCard(
                      scheme: scheme,
                      bearing: bearing,
                      heading: heading,
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: 18),

                    // ── Kaaba destination ──
                    _destinationCard(scheme)
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.12, end: 0),

                    const SizedBox(height: 24),

                    // ── Instructions ──
                    _instructionsCard(scheme, isDark)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.12, end: 0),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ INTRO ═══════════════════════════

  Widget _intro(ColorScheme scheme) {
    return Column(
      children: [
        Text(
          'Find Your Qibla',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Align yourself towards the sacred Kaaba.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ COMPASS HERO ═══════════════════════════

  Widget _compassHero({
    required ColorScheme scheme,
    required bool isDark,
    required double heading,
    required double bearing,
    required double needleAngle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(
          constraints.maxWidth,
          350.0,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerLow,
              ]
                  : [
                Colors.white,
                scheme.primary.withOpacity(0.045),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: scheme.primary.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(
                  isDark ? 0.06 : 0.07,
                ),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // Compass status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.green.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE COMPASS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Compass
              SizedBox(
                width: size,
                height: size,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: heading),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedHeading, child) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(end: needleAngle),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedNeedle, child) {
                        return CustomPaint(
                          painter: _PremiumCompassPainter(
                            heading: animatedHeading,
                            needleAngle: animatedNeedle,
                            scheme: scheme,
                            isDark: isDark,
                          ),
                          child: Center(
                            child: _CompassCenter(
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Rotate your phone to find the Qibla',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════ BEARING CARD ═══════════════════════════

  Widget _bearingCard({
    required ColorScheme scheme,
    required double bearing,
    required double heading,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.17)!,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QIBLA BEARING',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Direction from North',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${bearing.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ DESTINATION ═══════════════════════════

  Widget _destinationCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.primary.withOpacity(0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: scheme.primary,
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'directionToKaaba'.tr,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'meccaSaudiArabia'.tr,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: scheme.primary,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ INSTRUCTIONS ═══════════════════════════

  Widget _instructionsCard(
      ColorScheme scheme,
      bool isDark,
      ) {
    final steps = [
      'qiblaStep1'.tr,
      'qiblaStep2'.tr,
      'qiblaStep3'.tr,
      'qiblaStep4'.tr,
    ];

    final icons = [
      Icons.phone_android_rounded,
      Icons.screen_rotation_rounded,
      Icons.explore_rounded,
      Icons.check_circle_outline_rounded,
    ];

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerLow
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.04 : 0.025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Text(
                'howToUse'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == steps.length - 1 ? 0 : 17,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.085),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icons[i],
                      color: scheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// COMPASS CENTER
// ═══════════════════════════════════════════════════════════════════════

class _CompassCenter extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;

  const _CompassCenter({
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.22)!,
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.mosque_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PREMIUM COMPASS PAINTER
// ═══════════════════════════════════════════════════════════════════════

class _PremiumCompassPainter extends CustomPainter {
  final double heading;
  final double needleAngle;
  final ColorScheme scheme;
  final bool isDark;

  _PremiumCompassPainter({
    required this.heading,
    required this.needleAngle,
    required this.scheme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2;

    final faceColor = isDark
        ? scheme.surfaceContainerHigh
        : const Color(0xFFFAFCFB);

    // ── Outer ambient glow ──
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..color = scheme.primary.withOpacity(0.045)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          18,
        ),
    );

    // ── Outer metallic ring ──
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..shader = SweepGradient(
          colors: [
            scheme.primary.withOpacity(0.12),
            MejlisPalette.gold.withOpacity(0.8),
            scheme.primary.withOpacity(0.12),
            MejlisPalette.gold.withOpacity(0.8),
            scheme.primary.withOpacity(0.12),
          ],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // ── Compass face ──
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()..color = faceColor,
    );

    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..color = scheme.primary.withOpacity(0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Rotating compass details ──
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);

    // Tick marks
    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;

      final major = i % 30 == 0;
      final medium = i % 10 == 0;

      final outer = radius - 18;
      final inner = major
          ? radius - 34
          : medium
          ? radius - 27
          : radius - 23;

      final start = Offset(
        outer * math.cos(angle),
        outer * math.sin(angle),
      );

      final end = Offset(
        inner * math.cos(angle),
        inner * math.sin(angle),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = major
              ? scheme.primary.withOpacity(0.85)
              : scheme.onSurface.withOpacity(0.20)
          ..strokeWidth = major ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cardinal labels
    _drawLabel(
      canvas,
      'N',
      Offset(0, -radius + 48),
      scheme.error,
      15,
    );

    _drawLabel(
      canvas,
      'S',
      Offset(0, radius - 48),
      scheme.onSurfaceVariant,
      13,
    );

    _drawLabel(
      canvas,
      'E',
      Offset(radius - 48, 0),
      scheme.onSurfaceVariant,
      13,
    );

    _drawLabel(
      canvas,
      'W',
      Offset(-radius + 48, 0),
      scheme.onSurfaceVariant,
      13,
    );

    // Decorative intermediate direction markers
    for (int i = 0; i < 360; i += 45) {
      if (i % 90 == 0) continue;

      final angle = (i - 90) * math.pi / 180;
      final position = Offset(
        (radius - 48) * math.cos(angle),
        (radius - 48) * math.sin(angle),
      );

      canvas.drawCircle(
        position,
        2.5,
        Paint()..color = MejlisPalette.gold,
      );
    }

    canvas.restore();

    // ── Qibla direction needle ──
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(
      (needleAngle - 90) * math.pi / 180,
    );

    final needleLength = radius * 0.57;

    // Needle glow
    canvas.drawCircle(
      Offset(needleLength, 0),
      17,
      Paint()
        ..color = MejlisPalette.gold.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          13,
        ),
    );

    // Needle body
    final needlePath = Path()
      ..moveTo(needleLength, 0)
      ..lineTo(needleLength - 24, -10)
      ..lineTo(needleLength - 17, 0)
      ..lineTo(needleLength - 24, 10)
      ..close();

    canvas.drawPath(
      needlePath,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFD978),
            Color(0xFFC38A28),
          ],
        ).createShader(
          Rect.fromLTWH(
            needleLength - 24,
            -10,
            24,
            20,
          ),
        ),
    );

    // Decorative trail
    canvas.drawLine(
      Offset(-5, 0),
      Offset(needleLength - 22, 0),
      Paint()
        ..color = MejlisPalette.gold.withOpacity(0.35)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // ── Center rings ──
    canvas.drawCircle(
      center,
      43,
      Paint()
        ..color = scheme.primary.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawCircle(
      center,
      35,
      Paint()
        ..color = MejlisPalette.gold.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawLabel(
      Canvas canvas,
      String text,
      Offset position,
      Color color,
      double fontSize,
      ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
      covariant _PremiumCompassPainter oldDelegate,
      ) {
    return oldDelegate.heading != heading ||
        oldDelegate.needleAngle != needleAngle ||
        oldDelegate.isDark != isDark ||
        oldDelegate.scheme != scheme;
  }
}
