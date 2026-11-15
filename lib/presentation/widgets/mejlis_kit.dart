import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/themes/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  MEJLIS KIT v2 — the shared Arabian-Mejlis illustration & component kit.
///
///  Everything is hand-painted with CustomPaint (no image assets), so the
///  whole design system ships inside the Dart code and stays crisp on every
///  screen. Widgets are theme-aware and API-compatible with v1.
///
///  What's new in v2
///   • True interlocking Rub-el-Hizb arabesque lattice (stars + octagons)
///   • Layered 3-depth mosque skyline with lit windows, onion domes,
///     tiered minarets and crescent finials
///   • Lanterns with chain links, ribbed glass, flickering flame + halo
///   • Twinkling star field, crescent moon, ornate divider rosette
///   • Cards with gold bracket corners, buttons with press + sheen sweep
///   • Counter ring with ticks, glowing sweep arc and moving head
/// ─────────────────────────────────────────────────────────────────────────

// ───────────────────────────── SHARED HELPERS ─────────────────────────────

Path _regularPolygon(Offset c, double r, int n, [double rotation = 0]) {
  final p = Path();
  for (int i = 0; i < n; i++) {
    final a = rotation + 2 * math.pi * i / n;
    final pt = c + Offset(r * math.cos(a), r * math.sin(a));
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Four-pointed sparkle with concave sides.
Path _sparkle(Offset c, double r) {
  final k = r * 0.18;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
}

Path _crescentPath(Offset c, double r, {double bite = 0.78}) {
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(Rect.fromCircle(center: c + Offset(r * 0.42, -r * 0.18), radius: r * bite));
  return Path.combine(PathOperation.difference, outer, inner);
}

// ═════════════════════════════ ILLUSTRATIONS ═════════════════════════════

/// Interlocking Rub-el-Hizb lattice: 8-point stars (two overlapping squares)
/// with inner octagons, linked by small diamonds at every cell centre.
class ArabesquePainter extends CustomPainter {
  final Color lineColor;
  final double spacing;
  final double opacity;

  ArabesquePainter({
    this.lineColor = Colors.white,
    this.spacing = 54,
    this.opacity = 0.10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = spacing;
    final half = s * 0.5;
    final a = half / math.sqrt2; // half-side of the axis-aligned square

    final stroke = Paint()
      ..color = lineColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final fine = Paint()
      ..color = lineColor.withOpacity(opacity * 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final fill = Paint()
      ..color = lineColor.withOpacity(opacity * 0.20)
      ..style = PaintingStyle.fill;
    final dot = Paint()
      ..color = lineColor.withOpacity(opacity * 1.2)
      ..style = PaintingStyle.fill;

    final cols = (size.width / s).ceil() + 2;
    final rows = (size.height / s).ceil() + 2;

    for (int j = -1; j < rows; j++) {
      for (int i = -1; i < cols; i++) {
        final c = Offset(i * s, j * s);

        final sq = Path()..addRect(Rect.fromCenter(center: c, width: 2 * a, height: 2 * a));
        final dia = diamondPath(c, half);

        // overlapping squares → 8-point star (overlap gets a deeper tint)
        canvas.drawPath(sq, fill);
        canvas.drawPath(dia, fill);
        canvas.drawPath(sq, stroke);
        canvas.drawPath(dia, stroke);

        // inner octagon + centre dot
        canvas.drawPath(_regularPolygon(c, a * 0.62, 8, math.pi / 8), fine);
        canvas.drawCircle(c, 1.4, dot);

        // linking diamond at the cell centre
        final m = c + Offset(half, half);
        canvas.drawPath(diamondPath(m, s * 0.13), stroke);
        canvas.drawPath(diamondPath(m, s * 0.06), fine);
      }
    }
  }

  static Path eightPointStarPath(Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (math.pi / 8) * i - math.pi / 2;
      final radius = i.isEven ? r : r * 0.62;
      final point = center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    path.close();
    return path;
  }

  static Path diamondPath(Offset center, double r) {
    return Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant ArabesquePainter old) =>
      old.lineColor != lineColor || old.spacing != spacing || old.opacity != opacity;
}

/// Pointed horseshoe arch with an optional soft fill and a double outline.
class ArchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final bool doubleLine;

  ArchPainter({
    required this.color,
    this.strokeWidth = 2,
    this.fillColor,
    this.doubleLine = true,
  });

  Path _arch(Rect r) {
    final w = r.width;
    final h = r.height;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, r.top + h * 0.48)
      ..cubicTo(r.left, r.top + h * 0.20, r.left + w * 0.18, r.top + h * 0.06, r.left + w * 0.5, r.top)
      ..cubicTo(r.right - w * 0.18, r.top + h * 0.06, r.right, r.top + h * 0.20, r.right, r.top + h * 0.48)
      ..lineTo(r.right, r.bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final path = _arch(outer);

    if (fillColor != null) {
      final closed = Path.from(path)..close();
      canvas.drawPath(closed, Paint()..color = fillColor!);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);

    if (doubleLine) {
      final inset = strokeWidth * 3.2;
      final inner = Rect.fromLTRB(outer.left + inset, outer.top + inset, outer.right - inset, outer.bottom);
      canvas.drawPath(
        _arch(inner),
        paint
          ..color = color.withOpacity(color.opacity * 0.55)
          ..strokeWidth = strokeWidth * 0.55,
      );
      // keystone diamond
      canvas.drawPath(
        ArabesquePainter.diamondPath(Offset(size.width / 2, outer.top + inset * 0.5), strokeWidth * 1.3),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArchPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.fillColor != fillColor;
}

/// Three-depth mosque skyline: far rooftops, mid domes, and a front mosque
/// with a great onion dome, semi-domes, tiered minarets, crescent finials
/// and softly glowing windows. Geometric only — respectful and decorative.
class MosqueSkylinePainter extends CustomPainter {
  final Color silhouette;
  final Color glow;
  final Color windowColor;

  MosqueSkylinePainter({
    required this.silhouette,
    this.glow = Colors.white,
    this.windowColor = const Color(0xFFFFD97A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gy = h * 0.88; // ground line
    final a = silhouette.opacity;
    Color tone(double m) => silhouette.withOpacity((a * m).clamp(0.0, 1.0));

    final far = Paint()..color = tone(0.45);
    final mid = Paint()..color = tone(0.75);
    final front = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tone(0.9), tone(1.3)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final finialLine = Paint()
      ..color = tone(1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final win = Paint()..color = windowColor.withOpacity(0.80);
    final winSoft = Paint()..color = windowColor.withOpacity(0.30);

    // ── Far layer: small rooftops & two thin distant minarets ──
    for (final f in const [0.04, 0.17, 0.31, 0.69, 0.83, 0.96]) {
      final r = w * (0.028 + 0.012 * ((f * 100).round() % 3));
      _dome(canvas, w * f, h * 0.80, r, h * 0.12, far, finialLine, finial: false);
      canvas.drawRect(Rect.fromLTRB(w * f - r * 0.85, h * 0.80, w * f + r * 0.85, gy), far);
    }
    _minaret(canvas, w * 0.25, gy, w * 0.020, h * 0.55, far, finialLine, null);
    _minaret(canvas, w * 0.75, gy, w * 0.020, h * 0.58, far, finialLine, null);

    // ── Mid layer: flanking domes ──
    for (final f in const [0.22, 0.78]) {
      _dome(canvas, w * f, h * 0.72, w * 0.06, h * 0.20, mid, finialLine, finial: true);
      canvas.drawRect(Rect.fromLTRB(w * f - w * 0.054, h * 0.72, w * f + w * 0.054, gy), mid);
    }

    // ── Front layer ──
    // low connecting wall
    canvas.drawRect(Rect.fromLTRB(w * 0.10, gy - h * 0.07, w * 0.90, gy), front);

    // outer small domes
    for (final dir in const [-1, 1]) {
      final cx = w * 0.5 + dir * w * 0.335;
      _dome(canvas, cx, h * 0.76, w * 0.05, h * 0.13, front, finialLine, finial: true);
      canvas.drawRect(Rect.fromLTRB(cx - w * 0.045, h * 0.76, cx + w * 0.045, gy), front);
    }
    // semi-domes
    for (final dir in const [-1, 1]) {
      final cx = w * 0.5 + dir * w * 0.215;
      _dome(canvas, cx, h * 0.68, w * 0.075, h * 0.20, front, finialLine, finial: true);
      canvas.drawRect(Rect.fromLTRB(cx - w * 0.068, h * 0.68, cx + w * 0.068, gy), front);
      _arched(canvas, cx, gy - h * 0.06, w * 0.016, h * 0.10, win);
    }
    // great central dome + drum
    final cx = w * 0.5;
    _dome(canvas, cx, h * 0.60, w * 0.15, h * 0.36, front, finialLine, finial: true);
    canvas.drawRect(Rect.fromLTRB(cx - w * 0.136, h * 0.60, cx + w * 0.136, gy), front);
    for (final dx in const [-0.07, 0.0, 0.07]) {
      _arched(canvas, cx + w * dx, gy - h * 0.05, w * 0.017, h * 0.13, win);
    }

    // arcade glow between domes
    for (int i = 0; i < 6; i++) {
      final ax = w * (0.17 + i * 0.012) + (i < 3 ? 0 : w * 0.54);
      _arched(canvas, ax, gy - h * 0.005, w * 0.012, h * 0.045, winSoft);
    }

    // main minarets
    _minaret(canvas, w * 0.095, gy, w * 0.042, h * 0.82, front, finialLine, win);
    _minaret(canvas, w * 0.905, gy, w * 0.042, h * 0.76, front, finialLine, win);

    // ground band
    canvas.drawRect(Rect.fromLTRB(0, gy, w, h), front);

    // subtle warm horizon glow along the ground
    canvas.drawRect(
      Rect.fromLTRB(0, gy - 2, w, gy + 1.5),
      Paint()..color = glow.withOpacity(0.10),
    );
  }

  void _dome(Canvas canvas, double cx, double baseY, double r, double height, Paint paint, Paint line,
      {bool finial = true}) {
    final apexY = baseY - height;
    final path = Path()
      ..moveTo(cx - r, baseY)
      ..cubicTo(cx - r * 1.12, baseY - height * 0.52, cx - r * 0.62, baseY - height * 0.80, cx, apexY)
      ..cubicTo(cx + r * 0.62, baseY - height * 0.80, cx + r * 1.12, baseY - height * 0.52, cx + r, baseY)
      ..close();
    canvas.drawPath(path, paint);

    if (finial) {
      canvas.drawLine(Offset(cx, apexY), Offset(cx, apexY - height * 0.16), line);
      canvas.drawPath(_crescentPath(Offset(cx, apexY - height * 0.27), math.max(3.2, height * 0.13)), paint);
    }
  }

  void _arched(Canvas canvas, double cx, double bottom, double w, double h, Paint p) {
    final r = w / 2;
    final path = Path()
      ..moveTo(cx - r, bottom)
      ..lineTo(cx - r, bottom - h + r)
      ..arcToPoint(Offset(cx + r, bottom - h + r), radius: Radius.circular(r))
      ..lineTo(cx + r, bottom)
      ..close();
    canvas.drawPath(path, p);
  }

  void _minaret(Canvas canvas, double cx, double baseY, double width, double height, Paint paint, Paint line,
      Paint? windows) {
    final y66 = baseY - height * 0.66;
    final y86 = baseY - height * 0.86;
    final top = baseY - height;

    // lower shaft
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(cx - width / 2, y66, cx + width / 2, baseY), Radius.circular(width * 0.12)),
      paint,
    );
    // lower balcony
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y66), width: width * 1.75, height: height * 0.045),
        const Radius.circular(2),
      ),
      paint,
    );
    // upper shaft
    canvas.drawRect(Rect.fromLTRB(cx - width * 0.33, y86, cx + width * 0.33, y66), paint);
    // upper balcony
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, y86), width: width * 1.2, height: height * 0.032),
        const Radius.circular(2),
      ),
      paint,
    );
    // onion cap
    final cap = Path()
      ..moveTo(cx - width * 0.42, y86)
      ..cubicTo(cx - width * 0.62, y86 - height * 0.05, cx - width * 0.14, top + height * 0.05, cx, top)
      ..cubicTo(cx + width * 0.14, top + height * 0.05, cx + width * 0.62, y86 - height * 0.05, cx + width * 0.42, y86)
      ..close();
    canvas.drawPath(cap, paint);
    canvas.drawLine(Offset(cx, top), Offset(cx, top - height * 0.05), line);
    canvas.drawPath(_crescentPath(Offset(cx, top - height * 0.085), math.max(2.4, height * 0.035)), paint);

    if (windows != null) {
      for (final f in const [0.22, 0.40, 0.55]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, baseY - height * f), width: width * 0.16, height: height * 0.05),
            const Radius.circular(1.5),
          ),
          windows,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MosqueSkylinePainter old) =>
      old.silhouette != silhouette || old.glow != glow || old.windowColor != windowColor;
}

/// Crescent moon with a soft halo.
class CrescentMoonPainter extends CustomPainter {
  final Color color;
  final Color glow;
  CrescentMoonPainter({this.color = const Color(0xFFFFE9A8), this.glow = const Color(0xFFFFD97A)});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * 0.36;
    canvas.drawCircle(
      c,
      r * 2.2,
      Paint()
        ..shader = RadialGradient(colors: [glow.withOpacity(0.30), glow.withOpacity(0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 2.2)),
    );
    canvas.drawPath(
      _crescentPath(c, r),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant CrescentMoonPainter old) => old.color != color || old.glow != glow;
}

/// A swaying hanging lantern with chain links, ribbed glass and a
/// flickering flame + halo. The signature Mejlis animation.
class HangingLantern extends StatefulWidget {
  final double size;
  final Color glowColor;
  final Color bodyColor;
  final Duration period;
  const HangingLantern({
    super.key,
    this.size = 46,
    this.glowColor = const Color(0xFFFFD97A),
    this.bodyColor = const Color(0xFFC9A227),
    this.period = const Duration(seconds: 4),
  });

  @override
  State<HangingLantern> createState() => _HangingLanternState();
}

class _HangingLanternState extends State<HangingLantern> with TickerProviderStateMixin {
  late final AnimationController _swingCtrl =
  AnimationController(vsync: this, duration: widget.period)..repeat(reverse: true);
  late final AnimationController _flameCtrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
  late final Animation<double> _swing = CurvedAnimation(parent: _swingCtrl, curve: Curves.easeInOut);

  @override
  void dispose() {
    _swingCtrl.dispose();
    _flameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_swing, _flameCtrl]),
        builder: (context, _) {
          return Transform.rotate(
            angle: (_swing.value * 2 - 1) * 0.11,
            alignment: Alignment.topCenter,
            child: CustomPaint(
              size: Size(widget.size, widget.size * 1.5),
              painter: _LanternPainter(
                glow: widget.glowColor,
                body: widget.bodyColor,
                pulse: _flameCtrl.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  final Color glow;
  final Color body;
  final double pulse;
  _LanternPainter({required this.glow, required this.body, this.pulse = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final dark = Color.lerp(body, Colors.black, 0.38)!;
    final light = Color.lerp(body, Colors.white, 0.40)!;

    // Warm halo (breathes with the flame)
    final haloC = Offset(cx, h * 0.58);
    final haloR = w * (0.95 + 0.08 * pulse);
    canvas.drawCircle(
      haloC,
      haloR,
      Paint()
        ..shader = RadialGradient(colors: [glow.withOpacity(0.32 + 0.12 * pulse), glow.withOpacity(0)])
            .createShader(Rect.fromCircle(center: haloC, radius: haloR)),
    );

    // Chain links
    final chain = Paint()
      ..color = body
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (int i = 0; i < 4; i++) {
      final cy = h * (0.02 + 0.052 * i);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: i.isEven ? w * 0.06 : w * 0.032, height: h * 0.058),
        chain,
      );
    }

    // Cap (ogee dome) + finial ring
    final cap = Path()
      ..moveTo(cx - w * 0.18, h * 0.26)
      ..quadraticBezierTo(cx - w * 0.15, h * 0.17, cx, h * 0.135)
      ..quadraticBezierTo(cx + w * 0.15, h * 0.17, cx + w * 0.18, h * 0.26)
      ..close();
    canvas.drawPath(
      cap,
      Paint()
        ..shader = LinearGradient(colors: [dark, light, body])
            .createShader(Rect.fromLTWH(cx - w * 0.18, h * 0.13, w * 0.36, h * 0.13)),
    );
    canvas.drawCircle(Offset(cx, h * 0.115), w * 0.035, Paint()..color = light);

    // Body
    final bodyPath = Path()
      ..moveTo(cx - w * 0.17, h * 0.26)
      ..lineTo(cx + w * 0.17, h * 0.26)
      ..lineTo(cx + w * 0.30, h * 0.44)
      ..lineTo(cx + w * 0.24, h * 0.74)
      ..lineTo(cx, h * 0.865)
      ..lineTo(cx - w * 0.24, h * 0.74)
      ..lineTo(cx - w * 0.30, h * 0.44)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, light, body, dark],
          stops: const [0, 0.35, 0.65, 1],
        ).createShader(Rect.fromLTWH(cx - w * 0.30, 0, w * 0.60, h)),
    );

    // Glass with flame
    final glass = Path()
      ..moveTo(cx - w * 0.15, h * 0.385)
      ..lineTo(cx + w * 0.15, h * 0.385)
      ..lineTo(cx + w * 0.10, h * 0.70)
      ..lineTo(cx, h * 0.785)
      ..lineTo(cx - w * 0.10, h * 0.70)
      ..close();
    final flameC = Offset(cx, h * 0.56);
    final flameR = w * (0.24 + 0.03 * pulse);
    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
      glass.getBounds(),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.96),
            glow.withOpacity(0.92),
            Color.lerp(glow, body, 0.5)!.withOpacity(0.85),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(Rect.fromCircle(center: flameC, radius: flameR)),
    );
    canvas.restore();

    // Lattice ribs over the glass
    final rib = Paint()
      ..color = dark.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(glass, rib);
    canvas.drawLine(Offset(cx, h * 0.385), Offset(cx, h * 0.785), rib);
    canvas.drawLine(Offset(cx - w * 0.15, h * 0.385), Offset(cx + w * 0.10, h * 0.70), rib);
    canvas.drawLine(Offset(cx + w * 0.15, h * 0.385), Offset(cx - w * 0.10, h * 0.70), rib);

    // Rings
    final ring = Paint()
      ..color = light
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(cx - w * 0.30, h * 0.44), Offset(cx + w * 0.30, h * 0.44), ring);
    canvas.drawLine(Offset(cx - w * 0.24, h * 0.74), Offset(cx + w * 0.24, h * 0.74), ring);

    // Tassel
    canvas.drawLine(Offset(cx, h * 0.865), Offset(cx, h * 0.95), chain);
    canvas.drawCircle(Offset(cx, h * 0.965), w * 0.05, Paint()..color = light);
    canvas.drawLine(Offset(cx, h * 0.97), Offset(cx - w * 0.04, h * 1.0), chain);
    canvas.drawLine(Offset(cx, h * 0.97), Offset(cx + w * 0.04, h * 1.0), chain);
  }

  @override
  bool shouldRepaint(covariant _LanternPainter old) =>
      old.glow != glow || old.body != body || old.pulse != pulse;
}

/// Star field with soft glints. Pass [phase] (0..1) to make it twinkle,
/// or use the [TwinklingStars] widget which animates it for you.
class StarFieldPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double phase;
  StarFieldPainter({this.color = Colors.white, this.opacity = 0.8, this.phase = 0});

  static const List<Offset> _stars = [
    Offset(0.06, 0.18), Offset(0.15, 0.52), Offset(0.24, 0.28), Offset(0.33, 0.66),
    Offset(0.42, 0.16), Offset(0.52, 0.44), Offset(0.61, 0.24), Offset(0.70, 0.60),
    Offset(0.78, 0.20), Offset(0.88, 0.46), Offset(0.94, 0.26), Offset(0.11, 0.78),
    Offset(0.63, 0.80), Offset(0.86, 0.74), Offset(0.03, 0.44), Offset(0.20, 0.10),
    Offset(0.37, 0.40), Offset(0.47, 0.72), Offset(0.57, 0.08), Offset(0.74, 0.38),
    Offset(0.91, 0.08), Offset(0.98, 0.62), Offset(0.28, 0.84), Offset(0.68, 0.14),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final pos = Offset(s.dx * size.width, s.dy * size.height);
      final tw = 0.55 + 0.45 * math.sin(2 * math.pi * (phase + i * 0.137));
      final alpha = (opacity * tw).clamp(0.0, 1.0);

      if (i % 3 == 0) {
        final r = 4.4 * (0.8 + 0.2 * tw);
        canvas.drawCircle(pos, r * 1.6, Paint()..color = color.withOpacity(alpha * 0.12));
        canvas.drawPath(_sparkle(pos, r), Paint()..color = color.withOpacity(alpha));
      } else {
        canvas.drawCircle(pos, (i % 2 == 0) ? 1.5 : 1.1, Paint()..color = color.withOpacity(alpha));
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter old) =>
      old.color != color || old.opacity != opacity || old.phase != phase;
}

/// Animated, twinkling version of [StarFieldPainter].
class TwinklingStars extends StatefulWidget {
  final Color color;
  final double opacity;
  const TwinklingStars({super.key, this.color = Colors.white, this.opacity = 0.85});

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: StarFieldPainter(color: widget.color, opacity: widget.opacity, phase: _c.value),
        ),
      ),
    );
  }
}

// ═════════════════════════════ COMPONENTS ═════════════════════════════

/// Gold ornament divider: ─── ◆ ✦ ◆ ───  with a central 8-point rosette.
class OrnamentDivider extends StatelessWidget {
  final Color? color;
  final double width;
  const OrnamentDivider({super.key, this.color, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 22,
      child: CustomPaint(painter: _OrnamentPainter(color: color ?? MejlisPalette.gold)),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  final Color color;
  _OrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const gap = 34.0;

    // tapering hairlines (double: thick + fine)
    final leftRect = Rect.fromLTRB(0, 0, cx - gap, size.height);
    final rightRect = Rect.fromLTRB(cx + gap, 0, size.width, size.height);
    Paint lineP(Rect r, bool flip, double w, double a) => Paint()
      ..strokeWidth = w
      ..shader = LinearGradient(
        begin: flip ? Alignment.centerRight : Alignment.centerLeft,
        end: flip ? Alignment.centerLeft : Alignment.centerRight,
        colors: [color.withOpacity(0), color.withOpacity(a)],
      ).createShader(r);
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), lineP(leftRect, false, 1.2, 0.95));
    canvas.drawLine(Offset(cx + gap, cy), Offset(size.width, cy), lineP(rightRect, true, 1.2, 0.95));
    canvas.drawLine(Offset(size.width * 0.12, cy + 3.2), Offset(cx - gap - 6, cy + 3.2), lineP(leftRect, false, 0.6, 0.55));
    canvas.drawLine(Offset(cx + gap + 6, cy + 3.2), Offset(size.width * 0.88, cy + 3.2), lineP(rightRect, true, 0.6, 0.55));

    final goldFill = Paint()
      ..shader = MejlisPalette.goldGradient.createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 12));

    // outer dots + diamonds
    for (final dir in const [-1.0, 1.0]) {
      canvas.drawCircle(Offset(cx + dir * 27, cy), 1.6, Paint()..color = color);
      canvas.drawPath(ArabesquePainter.diamondPath(Offset(cx + dir * 19, cy), 3.4), goldFill);
    }

    // central rosette
    canvas.drawPath(ArabesquePainter.eightPointStarPath(Offset(cx, cy), 9.5), goldFill);
    canvas.drawPath(
      ArabesquePainter.eightPointStarPath(Offset(cx, cy), 9.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.5),
    );
    canvas.drawCircle(Offset(cx, cy), 2.2, Paint()..color = Colors.white.withOpacity(0.85));
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter old) => old.color != color;
}

/// Section header: gold tile, Marcellus display title and a gold underline.
class GoldSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const GoldSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: MejlisPalette.goldGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1),
                boxShadow: [
                  BoxShadow(color: MejlisPalette.gold.withOpacity(0.40), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 17,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0.40), Colors.white.withOpacity(0)],
                        ),
                      ),
                    ),
                  ),
                  Icon(icon, size: 19, color: const Color(0xFF2A2104)),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: GoogleFonts.marcellus(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 34,
                  height: 2.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [MejlisPalette.gold, MejlisPalette.gold.withOpacity(0)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!.tr,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Royal gold button: gloss highlight, bevel border, press-scale and a
/// periodic sheen sweep.
class MejlisGoldButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final bool dark;

  const MejlisGoldButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 50,
    this.fontSize = 15,
    this.dark = false,
  });

  @override
  State<MejlisGoldButton> createState() => _MejlisGoldButtonState();
}

class _MejlisGoldButtonState extends State<MejlisGoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3400));
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.onTap != null) _sheen.repeat();
  }

  @override
  void didUpdateWidget(covariant MejlisGoldButton old) {
    super.didUpdateWidget(old);
    if (widget.onTap != null && !_sheen.isAnimating) {
      _sheen.repeat();
    } else if (widget.onTap == null && _sheen.isAnimating) {
      _sheen.stop();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final radius = BorderRadius.circular(16);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: radius,
            child: Ink(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.dark ? MejlisPalette.goldGradientDark : MejlisPalette.goldGradient,
                borderRadius: radius,
                border: Border.all(color: MejlisPalette.goldDark.withOpacity(0.45), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: MejlisPalette.gold.withOpacity(_pressed ? 0.30 : 0.48),
                    blurRadius: _pressed ? 10 : 18,
                    offset: Offset(0, _pressed ? 3 : 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // top gloss
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: widget.height * 0.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.38), Colors.white.withOpacity(0)],
                          ),
                        ),
                      ),
                    ),
                    // sheen sweep
                    if (enabled)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _sheen,
                          builder: (_, __) => CustomPaint(painter: _SheenPainter(_sheen.value)),
                        ),
                      ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20, color: const Color(0xFF2A2104)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label.tr,
                            style: GoogleFonts.poppins(
                              fontSize: widget.fontSize,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2A2104),
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(color: Colors.white.withOpacity(0.35), offset: const Offset(0, 1), blurRadius: 0),
                              ],
                            ),
                          ),
                        ],
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
  }
}

class _SheenPainter extends CustomPainter {
  final double t; // 0..1 over the full cycle; sweep happens in the first 45%
  _SheenPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = (t / 0.45);
    if (p >= 1) return;
    final bandW = size.width * 0.28;
    final x = -bandW + (size.width + bandW * 2) * Curves.easeInOut.transform(p);
    canvas.save();
    canvas.translate(x, 0);
    canvas.transform(Matrix4.skewX(-0.35).storage);
    final rect = Rect.fromLTWH(0, 0, bandW, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withOpacity(0), Colors.white.withOpacity(0.42), Colors.white.withOpacity(0)],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) => old.t != t;
}

/// Ivory/emerald card with a gold hairline frame, soft shadow and (by
/// default) ornate gold bracket corners.
class MejlisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;
  final double radius;
  final VoidCallback? onTap;
  final bool ornate;

  const MejlisCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.gradient,
    this.radius = 18,
    this.onTap,
    this.ornate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ??
            (isDark
                ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B3760), Color(0xFF091426),
              ],
            )
                : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFEFA), Color(0xFFFAF4E4)],
            )),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MejlisPalette.gold.withOpacity(isDark ? 0.30 : 0.45)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.45) : Colors.brown.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: MejlisPalette.gold.withOpacity(isDark ? 0.06 : 0.10),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Padding(padding: padding, child: child),
                if (ornate)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _CardFramePainter(radius: radius, isDark: isDark)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardFramePainter extends CustomPainter {
  final double radius;
  final bool isDark;
  _CardFramePainter({required this.radius, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gold = MejlisPalette.gold;

    // inner hairline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        Radius.circular(math.max(2, radius - 4)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = gold.withOpacity(isDark ? 0.14 : 0.22),
    );

    // bracket corners
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = gold.withOpacity(isDark ? 0.75 : 0.85);
    final dot = Paint()..color = gold;
    const inset = 6.0;
    const len = 11.0;
    const rr = 5.0;

    void corner(Offset o, double rot) {
      canvas.save();
      canvas.translate(o.dx, o.dy);
      canvas.rotate(rot);
      final path = Path()
        ..moveTo(0, len)
        ..lineTo(0, rr)
        ..arcToPoint(const Offset(rr, 0), radius: const Radius.circular(rr))
        ..lineTo(len, 0);
      canvas.drawPath(path, p);
      canvas.drawCircle(const Offset(3.4, 3.4), 1.1, dot);
      canvas.restore();
    }

    corner(const Offset(inset, inset), 0);
    corner(Offset(size.width - inset, inset), math.pi / 2);
    corner(Offset(size.width - inset, size.height - inset), math.pi);
    corner(Offset(inset, size.height - inset), 3 * math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _CardFramePainter old) => old.radius != radius || old.isDark != isDark;
}

/// Circular gold progress ring for counters (tasbih / azkar / salawat):
/// tick marks, glowing sweep arc, moving head and milestone beads.
class GoldCountRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final Widget child;

  const GoldCountRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: progress.clamp(0.0, 1.0)),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gold = MejlisPalette.gold;
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final radius = outer - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // outer hairline
    canvas.drawCircle(
      center,
      outer - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withOpacity(0.28),
    );

    // inner disc + faint star
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..shader = RadialGradient(colors: [gold.withOpacity(0.12), gold.withOpacity(0.02)])
            .createShader(rect),
    );
    canvas.drawPath(
      ArabesquePainter.eightPointStarPath(center, radius * 0.62),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withOpacity(0.14),
    );

    // ticks
    const ticks = 66;
    for (int i = 0; i < ticks; i++) {
      final ang = -math.pi / 2 + 2 * math.pi * i / ticks;
      final major = i % 6 == 0;
      final r1 = radius - (major ? 19 : 14);
      final r2 = radius - 8;
      final reached = i / ticks <= progress && progress > 0;
      canvas.drawLine(
        center + Offset(r1 * math.cos(ang), r1 * math.sin(ang)),
        center + Offset(r2 * math.cos(ang), r2 * math.sin(ang)),
        Paint()
          ..strokeWidth = major ? 1.6 : 1.0
          ..strokeCap = StrokeCap.round
          ..color = gold.withOpacity(reached ? 0.85 : (major ? 0.34 : 0.20)),
      );
    }

    // track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = gold.withOpacity(0.15),
    );

    if (progress > 0) {
      final sweep = 2 * math.pi * progress;

      // glow under the arc
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = gold.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );

      // main arc
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [MejlisPalette.goldDark, gold, const Color(0xFFFFE08A)],
            stops: const [0.0, 0.6, 1.0],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect),
      );

      // head
      final ha = -math.pi / 2 + sweep;
      final head = center + Offset(radius * math.cos(ha), radius * math.sin(ha));
      canvas.drawCircle(head, 10, Paint()..color = gold.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(head, 5.2, Paint()..color = const Color(0xFFFFF2C2));
      canvas.drawCircle(head, 2.4, Paint()..color = gold);
    }

    // milestone beads
    final bead = Paint()..color = gold.withOpacity(0.9);
    for (int i = 0; i < 11; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 11);
      canvas.drawCircle(
        center + Offset(radius * math.cos(angle), radius * math.sin(angle)),
        2.4,
        bead,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// Small gold count badge (e.g. "3 photos") with gloss and bevel.
class GoldBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const GoldBadge({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: MejlisPalette.goldGradient,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: const Color(0xFF2A2104)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2A2104),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painted header for customer-facing Mejlis screens: emerald night sky
/// with warm lantern glow, arabesque lattice, twinkling stars, crescent
/// moon, a 3-depth mosque skyline and swaying lanterns.
class MejlisHeaderBackground extends StatelessWidget {
  final bool showSkyline;
  final bool showLanterns;
  const MejlisHeaderBackground({super.key, this.showSkyline = true, this.showLanterns = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Emerald fabric gradient
          // Royal navy fabric gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B3760),
                  Color(0xFF102442),
                  Color(0xFF091426),
                ],
              )
                  : MejlisPalette.emeraldGradient,
            ),
          ),

          // Warm lantern glow from the upper right
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, -0.9),
                radius: 1.0,
                colors: [MejlisPalette.gold.withOpacity(isDark ? 0.16 : 0.22), Colors.transparent],
              ),
            ),
          ),

          // Arabesque lattice
          CustomPaint(
            painter: ArabesquePainter(lineColor: Colors.white, spacing: 50, opacity: isDark ? 0.07 : 0.10),
          ),

          // Twinkling stars in the upper sky
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.62,
              widthFactor: 1,
              child: TwinklingStars(opacity: isDark ? 0.85 : 0.55),
            ),
          ),

          // Crescent moon
          if (showSkyline)
            Positioned(
              top: 16,
              right: 132,
              width: 34,
              height: 34,
              child: CustomPaint(painter: CrescentMoonPainter()),
            ),

          // Horizon glow
          if (showSkyline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 96,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [MejlisPalette.gold.withOpacity(0.16), Colors.transparent],
                  ),
                ),
              ),
            ),

          // Skyline silhouette
          if (showSkyline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 132,
              child: CustomPaint(
                painter: MosqueSkylinePainter(
                  silhouette: Colors.black.withOpacity(isDark ? 0.34 : 0.18),
                  glow: Colors.white,
                ),
              ),
            ),

          // Hanging lanterns
          if (showLanterns) ...[
            const Positioned(top: 3, right: 26, child: HangingLantern(size: 30)),
            Positioned(
              top: 3,
              right: 76,
              child: HangingLantern(size: 22, period: const Duration(seconds: 5)),
            ),
            Positioned(
              top: 3,
              right: 104,
              child: HangingLantern(size: 16, period: const Duration(milliseconds: 3400)),
            ),
          ],

          // Gold top hairline with highlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(gradient: MejlisPalette.goldGradient)),
          ),
          Positioned(
            top: 3,
            left: 0,
            right: 0,
            child: Container(height: 1, color: Colors.white.withOpacity(0.18)),
          ),

          // Legibility scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.10), Colors.transparent, Colors.black.withOpacity(0.38)],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Bottom gold-to-brand edge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [MejlisPalette.gold, scheme.secondary]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing halo for map markers / "live" hints: two staggered ripples
/// around a glowing gold core.
class PulsingHalo extends StatefulWidget {
  final double size;
  final Color color;
  final Duration period;
  const PulsingHalo({
    super.key,
    this.size = 46,
    this.color = MejlisPalette.gold,
    this.period = const Duration(milliseconds: 2200),
  });

  @override
  State<PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<PulsingHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _ring(double t) {
    final e = Curves.easeOut.transform(t);
    final s = widget.size * (0.3 + 0.7 * e);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withOpacity((1 - e) * 0.10),
        border: Border.all(color: widget.color.withOpacity((1 - e) * 0.8), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _ring(_ctrl.value),
              _ring((_ctrl.value + 0.5) % 1.0),
              Container(
                width: widget.size * 0.32,
                height: widget.size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: MejlisPalette.goldGradient,
                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
                  boxShadow: [BoxShadow(color: widget.color.withOpacity(0.65), blurRadius: 12)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Staggered entrance helper — apply to any widget inside a Column/List.
extension MejlisEntrance on Widget {
  Widget mejlisEnter({int delayMs = 0, double slide = 0.06}) {
    return animate()
        .fadeIn(delay: delayMs.ms, duration: 420.ms, curve: Curves.easeOutCubic)
        .slideY(begin: slide, end: 0, delay: delayMs.ms, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}