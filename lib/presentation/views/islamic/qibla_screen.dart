import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/islamic_sliver_appbar.dart';

class QiblaScreen extends GetView<IslamicController> {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startQiblaCompass();
    });
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Obx(() {
        // Calculate needle angle: Qibla Bearing - Device Compass Heading
        // (Ensure controller exposes `compassHeading.value` and `qiblaBearing.value`)
        final heading = controller.compassHeading.value;
        final bearing = controller.qiblaBearing.value;
        final needleAngle = (bearing - heading + 360) % 360;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            IslamicSliverAppBar(
              title: 'qiblaDirection'.tr,
              icon: Icons.explore_rounded,
              actions: [
                IconButton(
                  icon: const Icon(Icons.compass_calibration_rounded, color: Colors.white),
                  onPressed: controller.startQiblaCompass,
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
                            border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                          ),
                          child: CustomPaint(
                            painter: _CompassPainter(
                              qiblaAngle: needleAngle,
                              compassHeading: heading,
                              isDark: isDark,
                              scheme: scheme,
                            ),
                          ),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          child: Column(
                            children: [
                              Text('qibla'.tr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.primary)),
                              Text('${bearing.toStringAsFixed(1)}°',
                                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),

                    const SizedBox(height: 32),

                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Text('howToUse'.tr,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _instruction('qiblaStep1'.tr, scheme),
                          _instruction('qiblaStep2'.tr, scheme),
                          _instruction('qiblaStep3'.tr, scheme),
                          _instruction('qiblaStep4'.tr, scheme),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place_rounded, color: scheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('directionToKaaba'.tr,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                                Text('meccaSaudiArabia'.tr,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _instruction(String text, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double qiblaAngle;
  final double compassHeading;
  final bool isDark;
  final ColorScheme scheme;

  _CompassPainter({
    required this.qiblaAngle,
    required this.compassHeading,
    required this.isDark,
    required this.scheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const arrowLength = 60.0;

    canvas.drawCircle(
      center, radius,
      Paint()..color = isDark ? scheme.surfaceContainerHigh : Colors.white,
    );

    // Draw compass dial relative to physical compass heading
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-compassHeading * pi / 180);

    // Cardinal Points
    const textStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
    _drawText(canvas, 'N', const Offset(0, -90), textStyle.copyWith(color: scheme.error));
    _drawText(canvas, 'S', const Offset(0, 90), textStyle.copyWith(color: scheme.onSurfaceVariant));
    _drawText(canvas, 'E', const Offset(90, 0), textStyle.copyWith(color: scheme.onSurfaceVariant));
    _drawText(canvas, 'W', const Offset(-90, 0), textStyle.copyWith(color: scheme.onSurfaceVariant));

    // Compass tick marks
    for (int i = 0; i < 360; i += 10) {
      final rad = (i - 90) * pi / 180;
      final outer = radius - 8;
      final inner = i % 30 == 0 ? radius - 20 : radius - 14;
      final start = Offset(outer * cos(rad), outer * sin(rad));
      final end = Offset(inner * cos(rad), inner * sin(rad));
      canvas.drawLine(
        start, end,
        Paint()
          ..color = (i % 30 == 0)
              ? (isDark ? Colors.white70 : Colors.black54)
              : (isDark ? Colors.white30 : Colors.black26)
          ..strokeWidth = i % 30 == 0 ? 2 : 1,
      );
    }
    canvas.restore();

    // Draw Qibla Arrow pointing towards Kaaba
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((qiblaAngle - 90) * pi / 180);

    final arrowPaint = Paint()..color = scheme.primary;
    final arrowPath = Path()
      ..moveTo(arrowLength, 0)
      ..lineTo(arrowLength - 30, -12)
      ..lineTo(arrowLength - 30, -4)
      ..lineTo(arrowLength - 50, -4)
      ..lineTo(arrowLength - 50, 4)
      ..lineTo(arrowLength - 30, 4)
      ..lineTo(arrowLength - 30, 12)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    canvas.drawCircle(
      Offset(arrowLength, 0), 15,
      Paint()
        ..color = scheme.primary.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );
    canvas.restore();

    canvas.drawCircle(center, radius - 4, Paint()..color = (isDark ? Colors.white12 : Colors.black12)..style = PaintingStyle.stroke..strokeWidth = 1);
    canvas.drawCircle(center, 50, Paint()..color = (isDark ? Colors.white10 : Colors.black12)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.qiblaAngle != qiblaAngle ||
          oldDelegate.compassHeading != compassHeading ||
          oldDelegate.isDark != isDark;
}