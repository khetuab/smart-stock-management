import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/mejlis_kit.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  ISLAMIC CENTER — the hub shared by the admin and customer variants.
///
///  Layout:
///   1. Next-prayer hero (countdown ring)
///   2. Prayer-time pills
///   3. TASBIH — an interactive bead-ring centrepiece
///   4. Explore — compact two-per-row tiles, each with its own small
///      animated illustration (turning Quran page, swinging Qibla needle,
///      ticking clock, travelling tasbih bead, rising sun, beating heart,
///      rotating star, moving calendar day, falling zakat coin …)
///
///  All feature animations share ONE ticker and repaint via Listenable, so
///  the whole grid costs a single animation controller.
/// ─────────────────────────────────────────────────────────────────────────

const double _tau = 2 * math.pi;
const Color _cream = Color(0xFFFFF4D6);
const Color _goldL = Color(0xFFFFD97A);
const Color _goldD = Color(0xFF9A7B1E);

class IslamicHubBody extends StatelessWidget {
  const IslamicHubBody({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IslamicController>();
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Next-prayer hero ──
            _NextPrayerHero(controller: controller).mejlisEnter(delayMs: 0),

            const SizedBox(height: 16),

            // ── 2. Prayer time pills ──
            _PrayerTimePills(controller: controller).mejlisEnter(delayMs: 80),

            const SizedBox(height: 20),

            // ── 3. Tasbih centrepiece ──
            _TasbihCard(controller: controller).mejlisEnter(delayMs: 140),

            const SizedBox(height: 22),

            // ── 4. Explore ──
            Row(
              children: [
                Text(
                  'explore'.tr,
                  style: GoogleFonts.marcellus(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [MejlisPalette.gold.withOpacity(0.7), MejlisPalette.gold.withOpacity(0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            const _FeatureGrid(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════ HERO: NEXT PRAYER ═══════════════════════════

class _NextPrayerHero extends StatelessWidget {
  final IslamicController controller;
  const _NextPrayerHero({required this.controller});

  String _prayerLabel(String name) {
    switch (name) {
      case 'Fajr':
        return 'fajr'.tr;
      case 'Sunrise':
        return 'sunrise'.tr;
      case 'Dhuhr':
        return 'dhuhr'.tr;
      case 'Asr':
        return 'asr'.tr;
      case 'Maghrib':
        return 'maghrib'.tr;
      case 'Isha':
        return 'isha'.tr;
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3760), Color(0xFF102442)],
        )
            : MejlisPalette.emeraldGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: MejlisPalette.emerald.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: ArabesquePainter(lineColor: Colors.white, opacity: 0.07)),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MejlisPalette.goldLight.withOpacity(0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Obx(() {
                    final next = controller.nextPrayerName.value;
                    return SizedBox(
                      width: 86,
                      height: 86,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 86,
                            height: 86,
                            child: CircularProgressIndicator(
                              value: _progressFor(next),
                              strokeWidth: 5,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(MejlisPalette.goldLight),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                next.isEmpty ? '—' : _prayerLabel(next),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'remaining'.tr,
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'nextPrayer'.tr,
                          style: const TextStyle(
                            color: MejlisPalette.goldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                          controller.countdownText.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        )),
                        const SizedBox(height: 6),
                        Obx(() {
                          final loc = controller.currentLocation.value;
                          return Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  loc.isEmpty ? 'locating'.tr : loc,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progressFor(String name) {
    switch (name) {
      case 'Fajr':
        return 0.16;
      case 'Sunrise':
        return 0.33;
      case 'Dhuhr':
        return 0.5;
      case 'Asr':
        return 0.66;
      case 'Maghrib':
        return 0.83;
      case 'Isha':
        return 1.0;
      default:
        return 0.0;
    }
  }
}

// ═══════════════════════════ PRAYER TIME PILLS ═══════════════════════════

class _PrayerTimePills extends StatelessWidget {
  final IslamicController controller;
  const _PrayerTimePills({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final times = controller.prayerTimes;
      final next = controller.nextPrayerName.value;
      final loading = controller.isLoading.value;
      final entries = <MapEntry<String, String>>[];
      for (final name in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        final t = times[name];
        if (t != null) entries.add(MapEntry(name, t));
      }

      if (entries.isEmpty) {
        return Container(
          height: 52,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          )
              : Text(
            'prayerTimesUnavailable'.tr,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        );
      }

      return SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final isNext = entries[i].key == next;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isNext ? MejlisPalette.goldGradient : null,
                color: isNext
                    ? null
                    : Theme.of(context).brightness == Brightness.dark
                    ? scheme.surfaceContainerHigh
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNext ? Colors.transparent : MejlisPalette.gold.withOpacity(0.35),
                ),
                boxShadow: isNext
                    ? [BoxShadow(color: MejlisPalette.gold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _label(entries[i].key),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isNext ? const Color(0xFF2A2104) : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    entries[i].value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isNext ? const Color(0xFF2A2104) : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }

  String _label(String name) {
    switch (name) {
      case 'Fajr':
        return 'fajr'.tr;
      case 'Sunrise':
        return 'sunrise'.tr;
      case 'Dhuhr':
        return 'dhuhr'.tr;
      case 'Asr':
        return 'asr'.tr;
      case 'Maghrib':
        return 'maghrib'.tr;
      case 'Isha':
        return 'isha'.tr;
      default:
        return name;
    }
  }
}

// ═══════════════════════════ TASBIH CENTREPIECE ═══════════════════════════

class _TasbihCard extends StatefulWidget {
  final IslamicController controller;
  const _TasbihCard({required this.controller});

  @override
  State<_TasbihCard> createState() => _TasbihCardState();
}

class _TasbihCardState extends State<_TasbihCard> with SingleTickerProviderStateMixin {
  late final AnimationController _tap =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// Full dhikr phrase for each tasbih type used by the controller.
  static const Map<String, String> _phrases = {
    'تسبيح': 'سُبْحَانَ ٱللَّٰهِ',
    'تحميد': 'ٱلْحَمْدُ لِلَّٰهِ',
    'تكبير': 'ٱللَّٰهُ أَكْبَرُ',
    'صلاة على النبي': 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
  };

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  void _onTap() {
    final c = widget.controller;
    final complete = c.tasbihCount.value >= c.tasbihTotal.value;
    if (complete) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _tap.forward(from: 0);
    c.incrementTasbih();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B3760),
            Color(0xFF102442),
            Color(0xFF091426),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.38)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 22, offset: const Offset(0, 10)),
          BoxShadow(color: MejlisPalette.gold.withOpacity(0.10), blurRadius: 30, spreadRadius: -6),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: StarFieldPainter(opacity: 0.45))),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [MejlisPalette.gold.withOpacity(0.20), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── header ──
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: MejlisPalette.goldGradient,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: const Icon(Icons.blur_circular_rounded, size: 19, color: Color(0xFF2A2104)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'tasbih'.tr,
                              style: GoogleFonts.marcellus(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'digitalCounter'.tr,
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.75), size: 21),
                        onPressed: c.resetTasbih,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.open_in_full_rounded, color: Colors.white.withOpacity(0.75), size: 18),
                        onPressed: () => Get.toNamed(AppRoutes.tasbih),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ── ring + controls ──
                  LayoutBuilder(
                    builder: (context, box) {
                      final ring = math.min(176.0, box.maxWidth * 0.56);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildRing(ring),
                          const SizedBox(width: 10),
                          Expanded(child: _buildSide()),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRing(double ring) {
    final c = widget.controller;
    return Obx(() {
      // read observables at the top of the Obx builder
      final count = c.tasbihCount.value;
      final total = c.tasbihTotal.value;
      final btn = ring * 0.54;

      return SizedBox(
        width: ring,
        height: ring,
        child: AnimatedBuilder(
          animation: _tap,
          builder: (context, _) {
            final press = math.sin(math.pi * math.min(1.0, _tap.value * 3));
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(ring),
                  painter: _BeadRingPainter(count: count, total: total, tap: _tap.value),
                ),
                Transform.scale(
                  scale: 1 - 0.07 * press,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTap,
                    child: Container(
                      width: btn,
                      height: btn,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: MejlisPalette.goldGradient,
                        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: MejlisPalette.gold.withOpacity(0.45 + 0.25 * press),
                            blurRadius: 18 + 8 * press,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _goldD.withOpacity(0.35), width: 1),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: GoogleFonts.poppins(
                                  fontSize: btn * 0.34,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2A2104),
                                  height: 1.05,
                                ),
                              ),
                              Text(
                                '/ $total',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2A2104).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildSide() {
    final c = widget.controller;
    return Obx(() {
      final type = c.tasbihType.value;
      final total = c.tasbihTotal.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Align(
                key: ValueKey(type),
                alignment: Alignment.centerLeft,
                child: Text(
                  _phrases[type] ?? type,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    height: 1.55,
                    fontWeight: FontWeight.w700,
                    color: _goldL,
                    shadows: [Shadow(color: _goldL.withOpacity(0.35), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in c.tasbihWords)
                _TasbihChip(
                  label: w,
                  active: w == type,
                  arabic: true,
                  onTap: () => c.changeTasbihType(w),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final n in const [33, 99, 100])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TasbihChip(
                    label: '$n',
                    active: total == n,
                    onTap: () => c.setTasbihTotal(n.toDouble()),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}

class _TasbihChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool arabic;
  final VoidCallback onTap;
  const _TasbihChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.arabic = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: arabic ? 9 : 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: active ? MejlisPalette.goldGradient : null,
          color: active ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? Colors.transparent : MejlisPalette.gold.withOpacity(0.30),
          ),
        ),
        child: Text(
          label,
          style: arabic
              ? GoogleFonts.amiri(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF2A2104) : Colors.white.withOpacity(0.82),
          )
              : TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF2A2104) : Colors.white.withOpacity(0.82),
          ),
        ),
      ),
    );
  }
}

/// A prayer-bead ring: 33 glossy beads on a gold string with an imam bead
/// and tassel at the top. Beads light up gold as the count progresses.
class _BeadRingPainter extends CustomPainter {
  final int count;
  final int total;
  final double tap;
  _BeadRingPainter({required this.count, required this.total, required this.tap});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ctr = size.center(Offset.zero);
    final r = w / 2 - w * 0.14;
    const n = 33;
    final lit = total <= 0 ? 0 : math.min(n, ((count / total) * n).floor());
    final br = math.pi * r / (n + 1) * 0.78;

    // halo
    canvas.drawCircle(
      ctr,
      r + br * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [MejlisPalette.gold.withOpacity(0.16), Colors.transparent],
        ).createShader(Rect.fromCircle(center: ctr, radius: r + br * 3)),
    );

    // string
    canvas.drawCircle(
      ctr,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _goldL.withOpacity(0.35),
    );

    // beads
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + _tau * (i + 1) / (n + 1);
      final pos = ctr + Offset(math.cos(a), math.sin(a)) * r;
      final on = i < lit;

      if (on && i >= lit - 3) {
        canvas.drawCircle(
          pos,
          br * 1.8,
          Paint()
            ..color = MejlisPalette.gold.withOpacity(0.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      canvas.drawCircle(
        pos,
        br,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 0.95,
            colors: on
                ? const [Color(0xFFFFF2C2), Color(0xFFE3C567), Color(0xFF9A7B1E)]
                : const [
              Color(0xFFA9C8F5),
              Color(0xFF416FAE),
              Color(0xFF102442),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: br)),
      );
    }

    // next bead marker
    if (lit < n) {
      final a = -math.pi / 2 + _tau * (lit + 1) / (n + 1);
      final pos = ctr + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(
        pos,
        br + 2.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withOpacity(0.7),
      );
    }

    // imam bead + tassel
    final top = ctr + Offset(0, -r);
    final ir = br * 1.65;
    final tl = w * 0.065;
    final thread = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = _goldL;
    final stemTop = top + Offset(0, -ir);
    canvas.drawLine(stemTop, stemTop + Offset(0, -tl * 0.55), thread);
    final knot = stemTop + Offset(0, -tl * 0.55);
    canvas.drawCircle(knot, 1.5, Paint()..color = _goldL);
    for (final dx in const [-2.6, 0.0, 2.6]) {
      canvas.drawLine(knot, knot + Offset(dx, -tl * 0.55), thread);
    }
    canvas.drawCircle(
      top,
      ir,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.4),
          colors: [Color(0xFFFFF2C2), Color(0xFFE3C567), Color(0xFF9A7B1E)],
        ).createShader(Rect.fromCircle(center: top, radius: ir)),
    );
    canvas.drawCircle(
      top,
      ir,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.55),
    );

    // tap ripple
    if (tap > 0 && tap < 1) {
      final e = Curves.easeOut.transform(tap);
      canvas.drawCircle(
        ctr,
        w * 0.27 + w * 0.22 * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = _goldL.withOpacity((1 - e) * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter old) =>
      old.count != count || old.total != total || old.tap != tap;
}

// ═══════════════════════════ FEATURE GRID ═══════════════════════════

enum _Art { quran, mushaf, qibla, prayer, tasbih, azkar, salawat, names, hijri, zakat }

class _Feature {
  final _Art art;
  final String label;
  final String subtitle;
  final List<Color> colors;
  final String route;
  const _Feature(this.art, this.label, this.subtitle, this.colors, this.route);
}

class _FeatureGrid extends StatefulWidget {
  const _FeatureGrid();

  @override
  State<_FeatureGrid> createState() => _FeatureGridState();
}

class _FeatureGridState extends State<_FeatureGrid> with SingleTickerProviderStateMixin {
  // ONE shared 12 s clock drives every illustration (loops are seamless
  // because every period used divides 12).
  late final AnimationController _clock =
  AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature(_Art.quran, 'quran'.tr, 'readListen'.tr, const [Color(0xFF1F8A5B), Color(0xFF0B6E4F)], AppRoutes.quran),
      //_Feature(_Art.mushaf, 'mushaf'.tr, 'pageImages'.tr, const [Color(0xFF2E7D32), Color(0xFF1B5E20)], AppRoutes.quranmushaf),
      _Feature(_Art.qibla, 'qibla'.tr, 'findDirection'.tr, const [Color(0xFF00897B), Color(0xFF00695C)], AppRoutes.qibla),
      _Feature(_Art.prayer, 'prayerTimes'.tr, 'todaysSchedule'.tr, const [Color(0xFF1E88E5), Color(0xFF1565C0)], AppRoutes.prayerTimes),
      _Feature(_Art.tasbih, 'tasbih'.tr, 'digitalCounter'.tr, const [Color(0xFF8E24AA), Color(0xFF6A1B9A)], AppRoutes.tasbih),
      _Feature(_Art.azkar, 'azkar'.tr, 'morningEvening'.tr, const [Color(0xFFF9A825), Color(0xFFC17908)], AppRoutes.azkar),
      _Feature(_Art.salawat, 'salawat'.tr, 'blessTheProphet'.tr, const [Color(0xFFD81B60), Color(0xFFAD1457)], AppRoutes.salawat),
      _Feature(_Art.names, 'namesOfAllah'.tr, '99names'.tr, const [Color(0xFFD4A017), Color(0xFF9A7B1E)], AppRoutes.namesOfAllah),
      _Feature(_Art.hijri, 'hijriCalendar'.tr, 'convertDates'.tr, const [Color(0xFF6D4C41), Color(0xFF4E342E)], AppRoutes.hijriCalendar),
      //_Feature(_Art.zakat, 'zakat'.tr, 'calculateZakat'.tr, const [Color(0xFF039BE5), Color(0xFF0277BD)], AppRoutes.zakat),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 74,
      ),
      itemBuilder: (context, i) {
        return _FeatureTile(feature: features[i], clock: _clock)
            .mejlisEnter(delayMs: 40 * i, slide: 0.06);
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final Animation<double> clock;
  const _FeatureTile({required this.feature, required this.clock});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: MejlisPalette.gold.withOpacity(isDark ? 0.25 : 0.40)),
        ),
        child: InkWell(
          onTap: () => Get.toNamed(feature.route),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _ArtTile(kind: feature.art, colors: feature.colors, clock: clock),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.25,
                          color: scheme.onSurfaceVariant,
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
    );
  }
}

class _ArtTile extends StatelessWidget {
  final _Art kind;
  final List<Color> colors;
  final Animation<double> clock;
  const _ArtTile({required this.kind, required this.colors, required this.clock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(color: colors.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0.22), Colors.white.withOpacity(0)],
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                size: const Size.square(52),
                painter: _ArtPainter(kind, clock),
              ),
            ),
            if (kind == _Art.names)
              Text(
                'الله',
                style: GoogleFonts.amiri(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                  shadows: [Shadow(color: _goldL.withOpacity(0.8), blurRadius: 8)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ ANIMATED FEATURE ILLUSTRATIONS ═══════════════════════

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Path _hubSparkle(Offset c, double r) {
  final k = r * 0.18;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
    ..close();
}

Path _hubCrescent(Offset c, double r) {
  final outer = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final inner = Path()
    ..addOval(Rect.fromCircle(center: c + Offset(r * 0.42, -r * 0.18), radius: r * 0.78));
  return Path.combine(PathOperation.difference, outer, inner);
}

class _ArtPainter extends CustomPainter {
  final _Art kind;
  final Animation<double> t;
  _ArtPainter(this.kind, this.t) : super(repaint: t);

  /// Phase 0..1 of a loop lasting [period] seconds (period must divide 12).
  double ph(double period) => (t.value * 12.0 / period) % 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48.0);
    switch (kind) {
      case _Art.quran:
        _quran(canvas);
        break;
      case _Art.mushaf:
        _mushaf(canvas);
        break;
      case _Art.qibla:
        _qibla(canvas);
        break;
      case _Art.prayer:
        _prayer(canvas);
        break;
      case _Art.tasbih:
        _tasbih(canvas);
        break;
      case _Art.azkar:
        _azkar(canvas);
        break;
      case _Art.salawat:
        _salawat(canvas);
        break;
      case _Art.names:
        _names(canvas);
        break;
      case _Art.hijri:
        _hijri(canvas);
        break;
      case _Art.zakat:
        _zakat(canvas);
        break;
    }
    canvas.restore();
  }

  // ── Quran: open book, a page turns, light rises above ──
  void _quran(Canvas cv) {
    final p = ph(4);
    final pulse = 0.5 + 0.5 * math.sin(_tau * p);

    final left = Path()
      ..moveTo(24, 39)
      ..lineTo(24, 25)
      ..quadraticBezierTo(16, 21.5, 8, 25)
      ..lineTo(8, 38)
      ..quadraticBezierTo(16, 34.5, 24, 39)
      ..close();
    final right = Path()
      ..moveTo(24, 39)
      ..lineTo(24, 25)
      ..quadraticBezierTo(32, 21.5, 40, 25)
      ..lineTo(40, 38)
      ..quadraticBezierTo(32, 34.5, 24, 39)
      ..close();
    cv.drawPath(left, _fill(_cream));
    cv.drawPath(right, _fill(_cream.withOpacity(0.92)));
    cv.drawPath(
      Path()
        ..moveTo(6.5, 39)
        ..quadraticBezierTo(16, 35.5, 24, 41)
        ..quadraticBezierTo(32, 35.5, 41.5, 39),
      _stroke(_goldL, 2),
    );

    final line = _stroke(_goldD.withOpacity(0.55), 0.8);
    for (int i = 0; i < 3; i++) {
      final y = 27.5 + i * 3.2;
      cv.drawLine(Offset(11, y + 0.4), Offset(21, y + 0.9), line);
      cv.drawLine(Offset(27, y + 0.9), Offset(37, y + 0.4), line);
    }

    // turning page
    if (p < 0.5) {
      final u = p / 0.5;
      final xe = 24 + 16 * math.cos(math.pi * u);
      final lift = math.sin(math.pi * u);
      final page = Path()
        ..moveTo(24, 25)
        ..quadraticBezierTo((24 + xe) / 2, 21.5 - 4 * lift, xe, 25 - 2 * lift)
        ..lineTo(xe, 38 - 2 * lift)
        ..quadraticBezierTo((24 + xe) / 2, 34.5 - 3 * lift, 24, 39)
        ..close();
      cv.drawPath(page, _fill(Colors.white));
      cv.drawPath(page, _stroke(_goldD.withOpacity(0.35), 0.7));
    }

    // light of the Quran
    cv.drawCircle(const Offset(24, 12), 7 + 2 * pulse, _fill(_goldL.withOpacity(0.18 + 0.12 * pulse)));
    cv.drawPath(_hubSparkle(const Offset(24, 12), 3.4 + 1.8 * pulse), _fill(_goldL));
    cv.drawPath(
      _hubSparkle(const Offset(14, 15), 1.6 + 0.8 * math.sin(_tau * (p + 0.5)).abs()),
      _fill(Colors.white.withOpacity(0.8)),
    );
    cv.drawPath(
      _hubSparkle(const Offset(34, 16), 1.4 + 0.8 * math.sin(_tau * (p + 0.25)).abs()),
      _fill(Colors.white.withOpacity(0.8)),
    );
  }

  // ── Mushaf: closed gilded book with swaying ribbon ──
  void _mushaf(Canvas cv) {
    final sway = 2.2 * math.sin(_tau * ph(3));

    cv.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(14, 9, 38, 41), const Radius.circular(3)),
      _fill(_cream),
    );
    final cover = RRect.fromRectAndRadius(const Rect.fromLTRB(11, 7, 35, 39), const Radius.circular(3));
    cv.drawRRect(cover, _fill(const Color(0xFF1B3760)));
    cv.drawRRect(cover.deflate(2.2), _stroke(_goldL, 1.0));
    cv.drawRect(
      const Rect.fromLTRB(11, 7, 14.5, 39),
      _fill(const Color(0xFF102442)),
    );

    cv.save();
    cv.translate(24.5, 21);
    cv.rotate(_tau * ph(12));
    cv.drawPath(ArabesquePainter.eightPointStarPath(Offset.zero, 7.5), _stroke(_goldL, 1.1));
    cv.restore();
    cv.drawCircle(const Offset(24.5, 21), 2.2, _fill(_goldL));

    cv.drawLine(const Offset(19, 31), const Offset(30, 31), _stroke(_goldL.withOpacity(0.8), 1.2));
    cv.drawLine(const Offset(21, 34), const Offset(28, 34), _stroke(_goldL.withOpacity(0.55), 1.0));

    cv.drawPath(
      Path()
        ..moveTo(30, 38)
        ..quadraticBezierTo(30 + sway, 43, 30 + sway * 1.4, 46.5),
      _stroke(const Color(0xFFE5484D), 2.4),
    );
  }

  // ── Qibla: compass, needle swings toward the Kaaba ──
  void _qibla(Canvas cv) {
    const ctr = Offset(24, 28);
    cv.drawCircle(ctr, 14, _fill(Colors.white.withOpacity(0.12)));
    cv.drawCircle(ctr, 14, _stroke(_cream, 1.6));
    for (int i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final long = i % 2 == 0;
      final d = Offset(math.cos(a), math.sin(a));
      cv.drawLine(ctr + d * (long ? 10.5 : 11.8), ctr + d * 13, _stroke(_cream.withOpacity(0.7), 1));
    }

    // Kaaba
    cv.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(20.5, 3, 27.5, 10), const Radius.circular(0.8)),
      _fill(const Color(0xFF1A1A1A)),
    );
    cv.drawLine(const Offset(20.5, 5.2), const Offset(27.5, 5.2), _stroke(_goldL, 1.1));
    cv.drawRect(const Rect.fromLTRB(23, 7, 25, 10), _fill(_goldL));

    // swinging needle
    final ang = 0.55 * math.sin(_tau * ph(6)) * (0.6 + 0.4 * math.cos(_tau * ph(3)));
    cv.save();
    cv.translate(24, 28);
    cv.rotate(ang);
    cv.drawPath(
      Path()
        ..moveTo(0, -11)
        ..lineTo(2.6, 0)
        ..lineTo(0, 3)
        ..lineTo(-2.6, 0)
        ..close(),
      _fill(_goldL),
    );
    cv.drawPath(
      Path()
        ..moveTo(0, 3)
        ..lineTo(2.2, 0)
        ..lineTo(0, 9)
        ..lineTo(-2.2, 0)
        ..close(),
      _fill(_cream.withOpacity(0.85)),
    );
    cv.restore();
    cv.drawCircle(ctr, 1.8, _fill(Colors.white));
  }

  // ── Prayer times: ticking clock under a crescent ──
  void _prayer(Canvas cv) {
    const ctr = Offset(24, 27);
    cv.drawCircle(ctr, 15, _fill(Colors.white.withOpacity(0.14)));
    cv.drawCircle(ctr, 15, _stroke(_cream, 1.8));
    for (int i = 0; i < 12; i++) {
      final a = i * _tau / 12;
      final long = i % 3 == 0;
      final d = Offset(math.cos(a), math.sin(a));
      cv.drawLine(ctr + d * (long ? 11.2 : 12.6), ctr + d * 13.8, _stroke(_cream.withOpacity(long ? 0.95 : 0.55), long ? 1.4 : 1));
    }
    final hAng = _tau * ph(12) - math.pi / 2;
    final mAng = _tau * ph(3) - math.pi / 2;
    cv.drawLine(ctr, ctr + Offset(math.cos(hAng), math.sin(hAng)) * 7, _stroke(Colors.white, 2.2));
    cv.drawLine(ctr, ctr + Offset(math.cos(mAng), math.sin(mAng)) * 11, _stroke(_goldL, 1.6));
    cv.drawCircle(ctr, 1.8, _fill(_goldL));

    cv.drawPath(_hubCrescent(const Offset(39, 8.5), 4.6), _fill(_goldL));
    final tw = 0.5 + 0.5 * math.sin(_tau * ph(2));
    cv.drawPath(_hubSparkle(const Offset(9, 9), 1.6 + tw), _fill(Colors.white.withOpacity(0.5 + 0.4 * tw)));
  }

  // ── Tasbih: a bead ring filling up, bead by bead ──
  void _tasbih(Canvas cv) {
    const ctr = Offset(24, 29);
    const r = 13.0;
    const n = 12;
    final lit = (ph(6) * (n + 1)).floor(); // 0..12

    cv.drawCircle(ctr, r, _stroke(_cream.withOpacity(0.35), 0.9));
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + _tau * (i + 1) / (n + 1);
      final pos = ctr + Offset(math.cos(a), math.sin(a)) * r;
      final on = i < lit;
      if (on && i == lit - 1) {
        cv.drawCircle(pos, 4.6, _fill(_goldL.withOpacity(0.35)));
      }
      cv.drawCircle(pos, 2.5, _fill(on ? _goldL : _cream.withOpacity(0.5)));
      cv.drawCircle(pos + const Offset(-0.7, -0.7), 0.8, _fill(Colors.white.withOpacity(on ? 0.9 : 0.5)));
    }
    final top = ctr + const Offset(0, -r);
    cv.drawCircle(top, 3.4, _fill(_goldL));
    cv.drawCircle(top, 3.4, _stroke(_goldD, 0.8));
    cv.drawLine(top + const Offset(0, -3.4), top + const Offset(0, -6.4), _stroke(_goldL, 1.2));
    const knot = Offset(24, 9.4);
    cv.drawCircle(knot, 1.2, _fill(_goldL));
    for (final dx in const [-2.0, 0.0, 2.0]) {
      cv.drawLine(knot, knot + Offset(dx, -4.4), _stroke(_goldL, 1.0));
    }
  }

  // ── Azkar: sun rising over the horizon, crescent & star ──
  void _azkar(Canvas cv) {
    final p = ph(4);
    final bob = 2.5 * math.sin(_tau * p);
    final center = Offset(24, 34 + bob);

    cv.save();
    cv.clipRect(const Rect.fromLTRB(0, 0, 48, 34));
    cv.drawCircle(center, 14, _fill(_goldL.withOpacity(0.22)));
    final rot = _tau * ph(12);
    for (int i = 0; i < 10; i++) {
      final a = _tau * i / 10 + rot;
      final d = Offset(math.cos(a), math.sin(a));
      cv.drawLine(center + d * 11, center + d * 14.8, _stroke(_goldL, 1.6));
    }
    cv.drawCircle(center, 8.2, _fill(_goldL));
    cv.drawCircle(center + const Offset(-2.4, -2.4), 3, _fill(Colors.white.withOpacity(0.45)));
    cv.restore();

    cv.drawLine(const Offset(6, 34), const Offset(42, 34), _stroke(_cream.withOpacity(0.85), 1.6));
    cv.drawLine(const Offset(16, 37.6), const Offset(32, 37.6), _stroke(_cream.withOpacity(0.40), 1.2));
    cv.drawLine(const Offset(20, 41), const Offset(28, 41), _stroke(_cream.withOpacity(0.25), 1.2));

    cv.drawPath(_hubCrescent(const Offset(10, 11), 4.2), _fill(Colors.white.withOpacity(0.92)));
    final tw = 0.5 + 0.5 * math.sin(_tau * ph(2));
    cv.drawPath(_hubSparkle(const Offset(38, 10), 1.8 + 1.2 * tw), _fill(Colors.white.withOpacity(0.55 + 0.4 * tw)));
  }

  // ── Salawat: a beating heart releasing sparkles ──
  void _salawat(Canvas cv) {
    final p = ph(2);
    final beat = math.pow(0.5 + 0.5 * math.sin(_tau * p), 3).toDouble();
    final w = 12.5 * (1 + 0.13 * beat);
    const ctr = Offset(24, 27);

    cv.drawCircle(ctr, 15 + 4 * beat, _fill(const Color(0xFFFF8A9B).withOpacity(0.18 + 0.15 * beat)));

    final heart = Path()
      ..moveTo(ctr.dx, ctr.dy + w * 0.6)
      ..cubicTo(ctr.dx - w * 1.15, ctr.dy - w * 0.05, ctr.dx - w * 0.7, ctr.dy - w * 1.0, ctr.dx, ctr.dy - w * 0.32)
      ..cubicTo(ctr.dx + w * 0.7, ctr.dy - w * 1.0, ctr.dx + w * 1.15, ctr.dy - w * 0.05, ctr.dx, ctr.dy + w * 0.6)
      ..close();
    cv.drawPath(
      heart,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7F7), Color(0xFFFFC2CC)],
        ).createShader(Rect.fromCircle(center: ctr, radius: w * 1.2)),
    );
    cv.drawCircle(ctr + Offset(-w * 0.38, -w * 0.28), w * 0.16, _fill(Colors.white.withOpacity(0.85)));

    final up = ph(4);
    for (int k = 0; k < 3; k++) {
      final u = (up + k / 3) % 1.0;
      final pos = Offset(24 + (k - 1) * 9.0, 18 - 13 * u);
      cv.drawPath(_hubSparkle(pos, 2.0), _fill(Colors.white.withOpacity(math.sin(math.pi * u).clamp(0.0, 1.0))));
    }
  }

  // ── Names of Allah: counter-rotating stars around the Name ──
  void _names(Canvas cv) {
    final p = ph(12);
    cv.drawCircle(const Offset(24, 24), 15, _fill(Colors.white.withOpacity(0.10)));

    cv.save();
    cv.translate(24, 24);
    cv.rotate(_tau * p);
    cv.drawPath(ArabesquePainter.eightPointStarPath(Offset.zero, 21), _stroke(_cream.withOpacity(0.85), 1.3));
    cv.restore();

    cv.save();
    cv.translate(24, 24);
    cv.rotate(-_tau * p * 2);
    cv.drawPath(ArabesquePainter.eightPointStarPath(Offset.zero, 14.5), _stroke(_goldL.withOpacity(0.85), 1.0));
    cv.restore();

    final a = _tau * ph(6);
    cv.drawCircle(Offset(24 + 21 * math.cos(a), 24 + 21 * math.sin(a)), 1.5, _fill(_goldL));
  }

  // ── Hijri calendar: the highlighted day travels across the month ──
  void _hijri(Canvas cv) {
    final body = RRect.fromRectAndRadius(const Rect.fromLTRB(8, 10, 40, 41), const Radius.circular(5));
    cv.drawRRect(body, _fill(_cream));
    cv.save();
    cv.clipRRect(body);
    cv.drawRect(const Rect.fromLTRB(8, 10, 40, 19), _fill(_goldD));
    cv.restore();

    for (final x in const [16.0, 32.0]) {
      cv.drawLine(Offset(x, 7.5), Offset(x, 12.5), _stroke(const Color(0xFF3E2A20), 2.2));
    }
    cv.drawPath(_hubCrescent(const Offset(24, 14.6), 3.6), _fill(_cream));

    final idx = (ph(12) * 12).floor() % 12;
    final pulse = 0.5 + 0.5 * math.sin(_tau * ph(2));
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 4; c++) {
        final i = r * 4 + c;
        final cell = RRect.fromRectAndRadius(
          Rect.fromLTWH(11.5 + c * 7.2, 21.5 + r * 6.4, 5, 4.4),
          const Radius.circular(1.2),
        );
        if (i == idx) {
          cv.drawRRect(cell, _fill(_goldL.withOpacity(0.75 + 0.25 * pulse)));
          cv.drawRRect(cell, _stroke(_goldD, 0.8));
        } else {
          cv.drawRRect(cell, _fill(const Color(0xFF6D4C41).withOpacity(0.28)));
        }
      }
    }
  }

  // ── Zakat: a coin drops into a gold pouch ──
  void _zakat(Canvas cv) {
    final u = ph(3);

    // coin (drawn first so the pouch hides it as it falls in)
    if (u < 0.82) {
      final fall = Curves.easeIn.transform(math.min(1.0, u / 0.8));
      final y = 3 + 18 * fall;
      final half = 1.0 + 2.6 * math.cos(_tau * u * 2.5).abs();
      final coin = Rect.fromCenter(center: Offset(24, y), width: half * 2, height: 6);
      cv.drawOval(coin, _fill(_goldL));
      cv.drawOval(coin, _stroke(_goldD, 0.8));
    }

    // pouch
    final body = Path()
      ..moveTo(18.5, 23)
      ..cubicTo(8, 28, 9, 42, 24, 42)
      ..cubicTo(39, 42, 40, 28, 29.5, 23)
      ..close();
    cv.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE08A), Color(0xFFC9A227)],
        ).createShader(const Rect.fromLTWH(8, 22, 32, 20)),
    );
    final flare = Path()
      ..moveTo(18.5, 23)
      ..lineTo(16.5, 17.5)
      ..quadraticBezierTo(24, 21.5, 31.5, 17.5)
      ..lineTo(29.5, 23)
      ..close();
    cv.drawPath(flare, _fill(const Color(0xFFE3B93A)));
    cv.drawLine(const Offset(18.2, 23.2), const Offset(29.8, 23.2), _stroke(const Color(0xFF7A5C10), 2));
    cv.drawPath(_hubCrescent(const Offset(24, 33), 5), _fill(const Color(0xFF7A5C10).withOpacity(0.75)));

    // sparkle as the coin lands
    if (u >= 0.8) {
      final s = ((u - 0.8) / 0.2).clamp(0.0, 1.0);
      cv.drawPath(
        _hubSparkle(const Offset(24, 18.5), 2 + 3 * math.sin(math.pi * s)),
        _fill(Colors.white.withOpacity(1 - s * 0.6)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.kind != kind;
}