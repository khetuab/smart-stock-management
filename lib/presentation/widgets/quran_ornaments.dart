import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/themes/app_theme.dart';
import 'mejlis_kit.dart';

/// Shared decorative pieces for the Quran reader + its settings sheet.
/// Place this file in: lib/presentation/widgets/quran_ornaments.dart

Path _starPath(Offset c, double outer, double inner, int points) {
  final p = Path();
  final step = math.pi / points;
  for (int i = 0; i < points * 2; i++) {
    final r = i.isEven ? outer : inner;
    final a = -math.pi / 2 + i * step;
    final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    if (i == 0) {
      p.moveTo(pt.dx, pt.dy);
    } else {
      p.lineTo(pt.dx, pt.dy);
    }
  }
  p.close();
  return p;
}

// ───────────────────────── STAR MEDALLION ─────────────────────────

/// An eight-point Islamic rosette. Used as the ayah-number marker and as
/// the ornament on surah banners. Pass an empty [label] for a pure glyph.
class StarMedallion extends StatelessWidget {
  final String label;
  final double size;
  final bool active;
  final Color? inkColor;

  const StarMedallion({
    super.key,
    this.label = '',
    this.size = 36,
    this.active = false,
    this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final idle = inkColor ?? (dark ? MejlisPalette.gold : MejlisPalette.goldDark);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(active: active),
        child: Center(
          child: label.isEmpty
              ? null
              : Text(
            label,
            style: TextStyle(
              fontSize: size * 0.33,
              fontWeight: FontWeight.w900,
              color: active ? const Color(0xFF2A2104) : idle,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final bool active;
  _StarPainter({required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    final rect = Offset.zero & size;

    final star = _starPath(c, outer, outer * 0.80, 8);
    if (active) {
      canvas.drawPath(
        star,
        Paint()..shader = MejlisPalette.goldGradient.createShader(rect),
      );
    } else {
      canvas.drawPath(star, Paint()..color = MejlisPalette.gold.withOpacity(0.10));
      canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeJoin = StrokeJoin.round
          ..color = MejlisPalette.gold.withOpacity(0.75),
      );
    }
    // inner ring
    canvas.drawCircle(
      c,
      outer * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = (active ? const Color(0xFF2A2104) : MejlisPalette.gold).withOpacity(active ? 0.35 : 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.active != active;
}

// ───────────────────────── ORNAMENT DIVIDER ─────────────────────────

/// ——— ◆ ——— fading gold divider.
class OrnamentDivider extends StatelessWidget {
  final double horizontalPadding;
  const OrnamentDivider({super.key, this.horizontalPadding = 0});

  @override
  Widget build(BuildContext context) {
    Widget line(bool fadeLeft) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fadeLeft
                ? [MejlisPalette.gold.withOpacity(0), MejlisPalette.gold.withOpacity(0.6)]
                : [MejlisPalette.gold.withOpacity(0.6), MejlisPalette.gold.withOpacity(0)],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
      child: Row(
        children: [
          line(true),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: MejlisPalette.gold,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          line(false),
        ],
      ),
    );
  }
}

// ───────────────────────── ARABESQUE BACKGROUND ─────────────────────────

/// A whisper-quiet geometric pattern behind the reading surface.
class ArabesqueBackground extends StatelessWidget {
  final Widget child;
  final Color color;
  const ArabesqueBackground({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _PatternPainter(color)),
          ),
        ),
        child,
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final Color color;
  _PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 64.0;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = color;
    final dot = Paint()..color = color;

    int row = 0;
    for (double y = 0; y < size.height + gap; y += gap * 0.75) {
      final shift = row.isOdd ? gap / 2 : 0.0;
      for (double x = -gap; x < size.width + gap; x += gap) {
        final c = Offset(x + shift, y);
        canvas.drawPath(_starPath(c, 15, 10, 8), stroke);
        canvas.drawCircle(c, 1.4, dot);
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) => old.color != color;
}

// ───────────────────────── EQUALIZER ─────────────────────────

/// Four bouncing bars — shows that an ayah is being recited.
class EqualizerBars extends StatefulWidget {
  final Color color;
  final double height;
  final bool animate;
  const EqualizerBars({
    super.key,
    required this.color,
    this.height = 16,
    this.animate = true,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final v = widget.animate
                  ? 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_c.value * 2 * math.pi + i * 1.4))
                  : 0.45;
              return Container(
                width: 3,
                height: widget.height * v,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}