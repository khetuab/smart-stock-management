import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/themes/app_theme.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/islamic_sliver_appbar.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/quran_ornaments.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  DIGITAL TASBIH — a real string of prayer beads
///
///   • A ring of 33 (or 99) glass-like beads around the counter. Every tap
///     slides the ring one bead, the counted beads turn gold and the latest
///     one glows at the pointer
///   • A fixed imame bead with a gently swaying tassel hangs at the bottom
///   • Big counter dial with press-in feedback, haptics, and a golden
///     "completed" state
///   • Dhikr picker, remaining / percent card, 33 · 99 switch, reset
/// ─────────────────────────────────────────────────────────────────────────
class TasbihScreen extends GetView<IslamicController> {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ArabesqueBackground(
        color: (isDark ? MejlisPalette.gold : MejlisPalette.goldDark).withOpacity(0.06),
        child: Obx(() {
          final count = controller.tasbihCount.value.toInt();
          final total = math.max(1, controller.tasbihTotal.value.toInt());
          final type = controller.tasbihType.value;
          final done = count >= total;
          final percent = ((count / total) * 100).clamp(0, 100).round();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                backgroundColor: scheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    'digitalTasbih'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  background: const MejlisHeaderBackground(showSkyline: false),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      // ── dhikr picker ──
                      _DhikrPicker(controller: controller, selected: type, scheme: scheme, isDark: isDark)
                          .animate()
                          .fadeIn(duration: 400.ms),

                      const SizedBox(height: 18),

                      // ── bead ring + dial ──
                      _TasbihDial(
                        count: count,
                        total: total,
                        word: type,
                        done: done,
                        scheme: scheme,
                        isDark: isDark,
                        onTap: () => _onTap(count, total),
                      )
                          .animate()
                          .fadeIn(delay: 150.ms, duration: 450.ms)
                          .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),

                      Text(
                        'tapCircleToCount'.tr,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 22),

                      // ── stats ──
                      _StatsCard(
                        remaining: math.max(0, total - count),
                        percent: percent,
                        progress: (count / total).clamp(0.0, 1.0),
                        scheme: scheme,
                        isDark: isDark,
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                      const SizedBox(height: 16),

                      // ── controls ──
                      Row(
                        children: [
                          Expanded(
                            child: _TotalSwitch(
                              total: total,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                controller.setTasbihTotal(v);
                              },
                              scheme: scheme,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              controller.resetTasbih();
                            },
                            icon: const Icon(Icons.restart_alt_rounded, size: 20),
                            label: Text('reset'.tr),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(color: MejlisPalette.gold.withOpacity(0.55)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 330.ms, duration: 400.ms),

                      // ── completed ──
                      if (done) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                MejlisPalette.gold.withOpacity(0.28),
                                MejlisPalette.gold.withOpacity(0.10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: MejlisPalette.gold.withOpacity(0.7)),
                          ),
                          child: Row(
                            children: [
                              const StarMedallion(size: 38, active: true),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'tasbihComplete'.tr,
                                  style: TextStyle(
                                    color: isDark ? MejlisPalette.gold : MejlisPalette.goldDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.2, end: 0)
                            .then()
                            .shimmer(duration: 1400.ms, color: Colors.white24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _onTap(int before, int total) {
    controller.incrementTasbih();
    final after = controller.tasbihCount.value.toInt();
    if (after >= total && before < total) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}

// ═════════════════════════════ DHIKR PICKER ═════════════════════════════

class _DhikrPicker extends StatelessWidget {
  final IslamicController controller;
  final String selected;
  final ColorScheme scheme;
  final bool isDark;
  const _DhikrPicker({
    required this.controller,
    required this.selected,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final words = controller.tasbihWords.toList();
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: words.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final word = words[i].toString();
          final active = selected == words[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              controller.changeTasbihType(words[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active
                    ? MejlisPalette.goldGradient
                    : LinearGradient(colors: [
                  isDark ? scheme.surfaceContainerHigh : Colors.white,
                  isDark ? scheme.surfaceContainerHigh : Colors.white,
                ]),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: active ? Colors.transparent : MejlisPalette.gold.withOpacity(0.4),
                ),
                boxShadow: active
                    ? [
                  BoxShadow(
                    color: MejlisPalette.gold.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Text(
                word,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                  color: active ? const Color(0xFF2A2104) : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════ DIAL (beads + tassel + counter) ═════════════════════════════

class _TasbihDial extends StatefulWidget {
  final int count;
  final int total;
  final String word;
  final bool done;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onTap;
  const _TasbihDial({
    required this.count,
    required this.total,
    required this.word,
    required this.done,
    required this.scheme,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_TasbihDial> createState() => _TasbihDialState();
}

class _TasbihDialState extends State<_TasbihDial> with SingleTickerProviderStateMixin {
  static const double _w = 300;
  static const double _h = 380;
  static const double _cy = 162; // ring centre y
  static const double _ring = 125; // ring radius

  late final AnimationController _sway =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..repeat(reverse: true);

  bool _pressed = false;

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final done = widget.done;

    // At most 99 beads are drawn; bigger totals are scaled onto 99.
    final beads = widget.total.clamp(1, 99);
    final counted = widget.total <= 99
        ? widget.count.clamp(0, beads)
        : ((widget.count / widget.total) * beads).floor().clamp(0, beads);
    final step = 2 * math.pi / beads;
    // Slide the ring so the last counted bead sits under the pointer.
    final rotation = counted >= 1 ? -(counted - 1) * step : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: SizedBox(
        width: _w,
        height: _h,
        child: Stack(
          children: [
            // beads
            TweenAnimationBuilder<double>(
              tween: Tween(end: rotation),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (_, rot, __) => CustomPaint(
                size: const Size(_w, _h),
                painter: _BeadRingPainter(
                  beads: beads,
                  counted: counted,
                  rotation: rot,
                  idle: scheme.onSurface.withOpacity(widget.isDark ? 0.30 : 0.20),
                  imame: scheme.primary,
                  cy: _cy,
                  radius: _ring,
                ),
              ),
            ),
            // tassel (own painter: only this repaints while swaying)
            CustomPaint(
              size: const Size(_w, _h),
              painter: _TasselPainter(
                sway: _sway,
                pivotY: _cy + _ring + 12,
              ),
            ),
            // dial
            Positioned(
              left: (_w - 190) / 2,
              top: _cy - 95,
              child: AnimatedScale(
                scale: _pressed ? 0.94 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: done
                          ? [MejlisPalette.gold, MejlisPalette.goldDark]
                          : [scheme.primary, scheme.tertiary],
                    ),
                    border: Border.all(color: MejlisPalette.gold.withOpacity(0.85), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (done ? MejlisPalette.gold : scheme.primary)
                            .withOpacity(_pressed ? 0.25 : 0.45),
                        blurRadius: _pressed ? 14 : 28,
                        spreadRadius: _pressed ? 1 : 4,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    ),
                    child: _dialContent(done),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialContent(bool done) {
    final ink = done ? const Color(0xFF2A2104) : Colors.white;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: done
              ? Icon(Icons.check_rounded, key: const ValueKey('done'), size: 54, color: ink)
              : Text(
            '${widget.count}',
            key: ValueKey(widget.count),
            style: TextStyle(
              color: ink,
              fontSize: 58,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
              height: 1.05,
            ),
          ),
        ),
        Text(
          '/ ${widget.total}',
          style: TextStyle(color: ink.withOpacity(0.75), fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            widget.word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withOpacity(0.7), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── bead ring ──

class _BeadRingPainter extends CustomPainter {
  final int beads;
  final int counted;
  final double rotation;
  final Color idle;
  final Color imame;
  final double cy;
  final double radius;

  _BeadRingPainter({
    required this.beads,
    required this.counted,
    required this.rotation,
    required this.idle,
    required this.imame,
    required this.cy,
    required this.radius,
  });

  void _bead(Canvas canvas, Offset p, double r, Color base) {
    final rect = Rect.fromCircle(center: p, radius: r);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.45),
        radius: 0.95,
        colors: [
          Color.lerp(base, Colors.white, 0.65)!,
          base,
          Color.lerp(base, Colors.black, 0.3)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawCircle(p, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, cy);
    final step = 2 * math.pi / beads;
    final r = (2 * math.pi * radius / beads * 0.40).clamp(2.5, 9.5).toDouble();

    // the string
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = MejlisPalette.gold.withOpacity(0.5),
    );

    final countedBase = Color.lerp(MejlisPalette.gold, MejlisPalette.goldDark, 0.3)!;
    int? activeIndex = counted >= 1 ? counted - 1 : null;

    Offset posOf(int i) {
      final a = -math.pi / 2 + i * step + rotation;
      return Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
    }

    for (int i = 0; i < beads; i++) {
      if (i == activeIndex) continue;
      _bead(canvas, posOf(i), r, i < counted ? countedBase : idle);
    }

    if (activeIndex != null) {
      final p = posOf(activeIndex);
      canvas.drawCircle(
        p,
        r * 2.1,
        Paint()
          ..color = MejlisPalette.gold.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      _bead(canvas, p, r * 1.3, MejlisPalette.gold);
    }

    // pointer (top)
    final tip = Offset(c.dx, c.dy - radius - 16);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 7, tip.dy - 11)
        ..lineTo(tip.dx + 7, tip.dy - 11)
        ..close(),
      Paint()..color = MejlisPalette.gold,
    );

    // imame (the big fixed bead where the string is knotted)
    final ip = Offset(c.dx, c.dy + radius);
    canvas.drawCircle(
      ip,
      17,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    _bead(canvas, ip, 13, imame);
    canvas.drawCircle(
      ip,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MejlisPalette.gold,
    );
    canvas.drawCircle(ip, 4, Paint()..color = MejlisPalette.gold);
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter old) =>
      old.beads != beads ||
          old.counted != counted ||
          old.rotation != rotation ||
          old.idle != idle ||
          old.imame != imame;
}

// ── tassel ──

class _TasselPainter extends CustomPainter {
  final Animation<double> sway;
  final double pivotY;

  _TasselPainter({required this.sway, required this.pivotY}) : super(repaint: sway);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final t = Curves.easeInOut.transform(sway.value);
    final angle = (t * 2 - 1) * 0.07;

    canvas.save();
    canvas.translate(cx, pivotY);
    canvas.rotate(angle);
    canvas.translate(-cx, -pivotY);

    final gold = MejlisPalette.gold;
    final goldDark = MejlisPalette.goldDark;

    // cord
    canvas.drawLine(
      Offset(cx, pivotY),
      Offset(cx, pivotY + 12),
      Paint()
        ..color = goldDark
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // head
    final head = Offset(cx, pivotY + 19);
    canvas.drawCircle(
      head,
      7,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(gold, Colors.white, 0.6)!, gold, goldDark],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: head, radius: 7)),
    );

    // fringe
    final fringeTop = pivotY + 27;
    final fringe = Paint()
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int k = -5; k <= 5; k++) {
      final end = Offset(cx + k * 4.2, fringeTop + 40 - k.abs() * 2.6);
      fringe.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [goldDark, gold.withOpacity(0.85)],
      ).createShader(Rect.fromPoints(Offset(cx, fringeTop), end));
      canvas.drawLine(Offset(cx + k * 0.8, fringeTop), end, fringe);
    }

    // skirt cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, fringeTop - 1), width: 16, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = goldDark,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TasselPainter old) => old.pivotY != pivotY;
}

// ═════════════════════════════ STATS ═════════════════════════════

class _StatsCard extends StatelessWidget {
  final int remaining;
  final int percent;
  final double progress;
  final ColorScheme scheme;
  final bool isDark;
  const _StatsCard({
    required this.remaining,
    required this.percent,
    required this.progress,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? MejlisPalette.gold : MejlisPalette.goldDark;

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: accent),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              stat('remaining'.tr, '$remaining'),
              Container(width: 1, height: 36, color: MejlisPalette.gold.withOpacity(0.3)),
              stat('progress'.tr, '$percent%'),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Stack(
                children: [
                  Container(height: 6, color: MejlisPalette.gold.withOpacity(0.18)),
                  FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(gradient: MejlisPalette.goldGradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ 33 · 99 SWITCH ═════════════════════════════

class _TotalSwitch extends StatelessWidget {
  final int total;
  final ValueChanged<double> onChanged;
  final ColorScheme scheme;
  final bool isDark;
  const _TotalSwitch({
    required this.total,
    required this.onChanged,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget option(int value) {
      final active = total == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value.toDouble()),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active
                  ? MejlisPalette.goldGradient
                  : const LinearGradient(colors: [Colors.transparent, Colors.transparent]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: active ? const Color(0xFF2A2104) : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
      ),
      child: Row(children: [option(33), option(99)]),
    );
  }
}