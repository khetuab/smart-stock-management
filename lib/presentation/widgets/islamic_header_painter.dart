import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shared header background for every Islamic feature screen. Same
/// glass-mesh gradient language as Dashboard/Purchase/Debts headers —
/// always driven by scheme.primary/scheme.tertiary, never a hardcoded
/// color — plus a faint 8-point star lattice and soft crescent silhouette
/// so the module reads as distinctly Islamic without depicting anything
/// sacred.
class IslamicHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  IslamicHeaderPainter({
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
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.36).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.65).toColor(),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(
        center, radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    glassOrb(Offset(width * 0.85, height * 0.12), 90, Colors.white, 0.14, 55);
    glassOrb(Offset(width * 0.12, height * 0.85), 70, secondaryColor, 0.28, 50);

    // Faint 8-point star lattice — a restrained nod to Islamic geometric
    // pattern tradition, drawn as thin outline stars at low opacity.
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    const spacing = 46.0;
    for (double y = -spacing; y < height + spacing; y += spacing) {
      for (double x = -spacing; x < width + spacing; x += spacing) {
        final offsetX = ((y / spacing).round() % 2 == 0) ? 0.0 : spacing / 2;
        _drawEightPointStar(canvas, Offset(x + offsetX, y), 53, starPaint);
      }
    }

    // Soft crescent silhouette, bottom-right corner — decorative only.
    final crescentPaint = Paint()..color = Colors.white.withOpacity(0.28);
    final outer = Path()..addOval(Rect.fromCircle(center: Offset(width * 0.92, height * 1.02), radius: 70));
    final inner = Path()..addOval(Rect.fromCircle(center: Offset(width * 0.97, height * 0.96), radius: 62));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), crescentPaint);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
  }

  void _drawEightPointStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (math.pi / 4) * i;
      final point = center + Offset(r * math.cos(angle), r * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}