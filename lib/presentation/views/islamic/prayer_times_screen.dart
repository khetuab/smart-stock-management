import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/themes/app_theme.dart';
import '../../controllers/azan_controller.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/islamic_sliver_appbar.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/quran_ornaments.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  PRAYER TIMES + AZAN
///
///   • Header with Hijri date, quick access to azan settings
///   • Location card with collapsible city search
///   • "Next prayer" hero: live countdown ring + one-tap azan toggle
///   • Azan card: master switch, voice picker + preview, permission banner
///   • Prayer cards with a per-prayer azan switch (Sunrise has no azan)
///   • Settings sheet: azan voices (with preview), Fajr voice, test azan,
///     calculation method, Asr school
/// ─────────────────────────────────────────────────────────────────────────

const _names = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
const _arabic = ['الفجر', 'الشروق', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
const _icons = [
  Icons.wb_twilight_rounded,
  Icons.wb_sunny_outlined,
  Icons.light_mode_rounded,
  Icons.wb_sunny_rounded,
  Icons.wb_twilight_rounded,
  Icons.nights_stay_rounded,
];

const _calcMethods = <int, String>{
  3: 'Muslim World League',
  2: 'ISNA (North America)',
  5: 'Egyptian General Authority',
  4: 'Umm al-Qura, Makkah',
  1: 'Karachi (UISK)',
  8: 'Gulf Region',
  9: 'Kuwait',
  10: 'Qatar',
  13: 'Diyanet, Turkey',
  15: 'Moonsighting Committee',
};

// ═════════════════════════════ TIME HELPERS ═════════════════════════════

int? _toMinutes(String? raw) {
  if (raw == null) return null;
  final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (m == null) return null;
  return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
}

class _NextInfo {
  final int index;
  final Duration remaining;
  final double fraction;
  final bool tomorrow;
  const _NextInfo(this.index, this.remaining, this.fraction, this.tomorrow);
}

_NextInfo? _computeNext(Map<String, String> times, DateTime now) {
  final secs = <int?>[
    for (final n in _names) _toMinutes(times[n]) == null ? null : _toMinutes(times[n])! * 60,
  ];
  final nowSec = now.hour * 3600 + now.minute * 60 + now.second;

  int? bestIdx;
  int bestTarget = 1 << 30;
  for (int i = 0; i < secs.length; i++) {
    final s = secs[i];
    if (s == null) continue;
    for (final t in [s, s + 86400]) {
      if (t > nowSec && t < bestTarget) {
        bestTarget = t;
        bestIdx = i;
      }
    }
  }
  if (bestIdx == null) return null;

  int prev = -(1 << 30);
  for (final s in secs) {
    if (s == null) continue;
    for (final t in [s - 86400, s]) {
      if (t <= nowSec && t > prev) prev = t;
    }
  }
  final span = bestTarget - prev;
  final fraction = span <= 0 ? 0.0 : ((nowSec - prev) / span).clamp(0.0, 1.0).toDouble();
  return _NextInfo(bestIdx, Duration(seconds: bestTarget - nowSec), fraction, bestTarget >= 86400);
}

String _two(int v) => v.toString().padLeft(2, '0');

String _countdown(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String _short(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '<1m';
}

String _dateLabel(DateTime d) {
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${wd[d.weekday - 1]} · ${mo[d.month - 1]} ${d.day}';
}

void _openAzanSheet() {
  Get.bottomSheet(
    const _AzanSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

// ═════════════════════════════ SCREEN ═════════════════════════════

class PrayerTimesScreen extends GetView<IslamicController> {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final azan = AzanController.to;

    return Scaffold(
      body: ArabesqueBackground(
        color: (isDark ? MejlisPalette.gold : MejlisPalette.goldDark).withOpacity(0.06),
        child: Obx(() {
          final loading = controller.isLoading.value;
          final times = Map<String, String>.from(controller.prayerTimes);
          final errorMessage = controller.errorMessage.value;
          final location = controller.currentLocation.value;
          final hijri = controller.hijriDate.value;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 170,
                backgroundColor: scheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    tooltip: azanTr('azanSettings', 'Azan settings'),
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                    onPressed: _openAzanSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: controller.fetchPrayerTimes,
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    'prayerTimes'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      const MejlisHeaderBackground(showSkyline: false),
                      if (hijri.isNotEmpty)
                        Positioned(
                          left: 20,
                          bottom: 48,
                          child: Row(
                            children: [
                              const Icon(Icons.nightlight_round, size: 14, color: MejlisPalette.gold),
                              const SizedBox(width: 6),
                              Text(
                                hijri,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (loading)
                SliverToBoxAdapter(child: _Skeleton(scheme: scheme, isDark: isDark))
              else if (times.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppEmptyState(
                          icon: Icons.access_time_rounded,
                          title: 'loadingPrayerTimes'.tr,
                          subtitle: errorMessage,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: controller.fetchPrayerTimes,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('retry'.tr),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _NowBuilder(
                    builder: (context, now) {
                      final next = _computeNext(times, now);
                      final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _LocationCard(
                              location: location.isNotEmpty ? location : 'loadingLocation'.tr,
                              date: _dateLabel(now),
                              controller: controller,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            if (next != null) ...[
                              _NextHero(
                                info: next,
                                time: times[_names[next.index]] ?? '--:--',
                                azan: azan,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _AzanCard(
                              azan: azan,
                              islamic: controller,
                              scheme: scheme,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            _SectionTitle(
                              title: azanTr('todaysPrayers', "Today's prayers"),
                              scheme: scheme,
                            ),
                            const SizedBox(height: 10),
                            for (int i = 0; i < _names.length; i++)
                              _PrayerRow(
                                index: i,
                                time: times[_names[i]] ?? '--:--',
                                isNext: next?.index == i,
                                isPassed: _toMinutes(times[_names[i]]) != null &&
                                    _toMinutes(times[_names[i]])! * 60 <= nowSec,
                                remaining: next?.index == i ? next!.remaining : null,
                                azan: azan,
                                scheme: scheme,
                                isDark: isDark,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'prayerTimesLocationNote'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Rebuilds its child every second with the current time.
class _NowBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;
  const _NowBuilder({required this.builder});

  @override
  State<_NowBuilder> createState() => _NowBuilderState();
}

class _NowBuilderState extends State<_NowBuilder> {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

// ═════════════════════════════ SHARED PIECES ═════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final ColorScheme scheme;
  const _SectionTitle({required this.title, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: MejlisPalette.goldGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Compact animated switch with a bell inside the thumb.
class _GoldSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _GoldSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: value ? MejlisPalette.goldGradient : null,
          color: value ? null : scheme.onSurface.withOpacity(0.12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                key: ValueKey(value),
                size: 14,
                color: value ? MejlisPalette.goldDark : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════ LOCATION ═════════════════════════════

class _LocationCard extends StatefulWidget {
  final String location;
  final String date;
  final IslamicController controller;
  final ColorScheme scheme;
  final bool isDark;
  const _LocationCard({
    required this.location,
    required this.date,
    required this.controller,
    required this.scheme,
    required this.isDark,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final accent = widget.isDark ? MejlisPalette.gold : MejlisPalette.goldDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: widget.isDark ? scheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MejlisPalette.gold.withOpacity(0.16),
                ),
                child: Icon(Icons.location_on_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'searchCityHint'.tr,
                onPressed: () => setState(() => _open = !_open),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _open ? Icons.close_rounded : Icons.travel_explore_rounded,
                    key: ValueKey(_open),
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 6, 4),
              child: _CitySearch(
                controller: widget.controller,
                scheme: scheme,
                isDark: widget.isDark,
                onPicked: () => setState(() => _open = false),
              ),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CitySearch extends StatefulWidget {
  final IslamicController controller;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onPicked;
  const _CitySearch({
    required this.controller,
    required this.scheme,
    required this.isDark,
    required this.onPicked,
  });

  @override
  State<_CitySearch> createState() => _CitySearchState();
}

class _CitySearchState extends State<_CitySearch> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final scheme = widget.scheme;
    final accent = widget.isDark ? MejlisPalette.gold : MejlisPalette.goldDark;
    final fill = widget.isDark ? scheme.surfaceContainerHighest : const Color(0xFFF7F3E6);

    return Column(
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          onChanged: c.searchCity,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'searchCityHint'.tr,
            hintStyle: TextStyle(color: scheme.onSurfaceVariant),
            prefixIcon: Icon(Icons.search_rounded, color: accent),
            suffixIcon: Obx(() {
              if (c.isSearchingCity.value) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (c.isManualLocation.value) {
                return IconButton(
                  icon: Icon(Icons.my_location_rounded, color: accent),
                  tooltip: 'useCurrentLocation'.tr,
                  onPressed: () {
                    _text.clear();
                    FocusScope.of(context).unfocus();
                    c.useCurrentLocation();
                    widget.onPicked();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            filled: true,
            fillColor: fill,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: MejlisPalette.gold, width: 1.4),
            ),
          ),
        ),
        Obx(() {
          if (c.citySuggestions.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: c.citySuggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: MejlisPalette.gold.withOpacity(0.18)),
              itemBuilder: (context, i) {
                final s = c.citySuggestions[i];
                return InkWell(
                  onTap: () {
                    _text.clear();
                    FocusScope.of(context).unfocus();
                    c.selectCity(s);
                    widget.onPicked();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.location_city_rounded, size: 19, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ═════════════════════════════ NEXT-PRAYER HERO ═════════════════════════════

class _NextHero extends StatelessWidget {
  final _NextInfo info;
  final String time;
  final AzanController azan;
  final bool isDark;
  const _NextHero({
    required this.info,
    required this.time,
    required this.azan,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = _names[info.index];
    final hasAzan = info.index != 1;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B3760),
            Color(0xFF102442),
          ],
        )
            : MejlisPalette.emeraldGradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.85), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: MejlisPalette.emerald.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Opacity(
                opacity: 0.10,
                child: StarMedallion(size: 190, active: true, inkColor: MejlisPalette.gold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'nextPrayer'.tr.toUpperCase(),
                              style: const TextStyle(
                                color: MejlisPalette.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (info.tomorrow) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'tomorrow'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          _arabic[info.index],
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiriQuran(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: MejlisPalette.gold,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 15, color: Colors.white.withOpacity(0.85)),
                                  const SizedBox(width: 6),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasAzan) _HeroAzanChip(azan: azan, prayer: name),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: info.fraction),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation(MejlisPalette.gold),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countdown(info.remaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'remaining'.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
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
}

class _HeroAzanChip extends StatelessWidget {
  final AzanController azan;
  final String prayer;
  const _HeroAzanChip({required this.azan, required this.prayer});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final master = azan.master.value;
      final on = master && azan.enabled[prayer] == true;

      return GestureDetector(
        onTap: () {
          if (!master) {
            azan.setMaster(true);
          } else {
            azan.togglePrayer(prayer);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: on ? MejlisPalette.goldGradient : null,
            color: on ? null : Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                size: 15,
                color: on ? const Color(0xFF2A2104) : Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 6),
              Text(
                on ? azanTr('azanOn', 'Azan on') : azanTr('azanOff', 'Azan off'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: on ? const Color(0xFF2A2104) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ═════════════════════════════ AZAN CARD ═════════════════════════════

class _AzanCard extends StatelessWidget {
  final AzanController azan;
  final IslamicController islamic;
  final ColorScheme scheme;
  final bool isDark;
  const _AzanCard({
    required this.azan,
    required this.islamic,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? MejlisPalette.gold : MejlisPalette.goldDark;

    return Obx(() {
      final on = azan.master.value;
      final permsMissing = on && (!azan.notificationsOk.value || !azan.exactAlarmOk.value);
      final voice = azan.voiceLabel(azan.sound.value);
      final previewing = azan.previewing.value == azan.sound.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? scheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: MejlisPalette.gold.withOpacity(on ? 0.6 : 0.28),
            width: on ? 1.4 : 1,
          ),
          boxShadow: on
              ? [
            BoxShadow(
              color: MejlisPalette.gold.withOpacity(0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: on ? MejlisPalette.goldGradient : null,
                    color: on ? null : MejlisPalette.gold.withOpacity(0.14),
                  ),
                  child: Icon(
                    on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: on ? const Color(0xFF2A2104) : accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        azanTr('azanTitle', 'Azan'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        on
                            ? azanTr('azanOnSub', 'Plays at every prayer you enable below')
                            : azanTr('azanOffSub', 'Turn on to hear the call to prayer'),
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _GoldSwitch(value: on, onChanged: azan.setMaster),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !on
                  ? const SizedBox(width: double.infinity)
                  : Column(
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _openAzanSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: MejlisPalette.gold.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.record_voice_over_rounded, size: 18, color: accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${azanTr('azanVoice', 'Voice')} · $voice',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    size: 20, color: scheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => azan.preview(azan.sound.value),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MejlisPalette.gold.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            previewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (permsMissing) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withOpacity(isDark ? 0.35 : 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20, color: scheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              !azan.notificationsOk.value
                                  ? azanTr('azanNeedNotif',
                                  'Allow notifications so the azan can play.')
                                  : azanTr('azanNeedExact',
                                  'Allow exact alarms so the azan plays on time.'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: azan.requestPermissions,
                            child: Text(azanTr('allow', 'Allow')),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (islamic.isManualLocation.value) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            azanTr('azanFollowsDevice',
                                'Azan always follows your device location, not the searched city.'),
                            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ═════════════════════════════ PRAYER ROW ═════════════════════════════

class _PrayerRow extends StatelessWidget {
  final int index;
  final String time;
  final bool isNext;
  final bool isPassed;
  final Duration? remaining;
  final AzanController azan;
  final ColorScheme scheme;
  final bool isDark;

  const _PrayerRow({
    required this.index,
    required this.time,
    required this.isNext,
    required this.isPassed,
    required this.remaining,
    required this.azan,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? MejlisPalette.gold : MejlisPalette.goldDark;
    final passed = isPassed && !isNext;
    final hasAzan = index != 1;
    final name = _names[index];

    Widget lead;
    if (isNext) {
      lead = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: MejlisPalette.goldGradient,
          boxShadow: [
            BoxShadow(color: MejlisPalette.gold.withOpacity(0.45), blurRadius: 12),
          ],
        ),
        child: Icon(_icons[index], size: 22, color: const Color(0xFF2A2104)),
      );
    } else if (passed) {
      lead = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MejlisPalette.emerald,
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.6)),
        ),
        child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
      );
    } else {
      lead = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MejlisPalette.gold.withOpacity(0.12),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.5), width: 1.2),
        ),
        child: Icon(_icons[index], size: 20, color: accent),
      );
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.fromLTRB(12, isNext ? 14 : 11, 14, isNext ? 14 : 11),
      decoration: BoxDecoration(
        gradient: isNext
            ? LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            MejlisPalette.gold.withOpacity(0.24),
            MejlisPalette.gold.withOpacity(0.07),
          ],
        )
            : null,
        color: isNext ? null : (isDark ? scheme.surfaceContainerHigh : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext ? MejlisPalette.gold : MejlisPalette.gold.withOpacity(0.2),
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: isNext
            ? [
          BoxShadow(
            color: MejlisPalette.gold.withOpacity(0.26),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
                        color: isNext ? accent : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _arabic[index],
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiriQuran(
                        fontSize: 17,
                        color: accent.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                if (isNext && remaining != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${'nextPrayer'.tr} · ${_short(remaining!)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: isNext ? accent : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          if (hasAzan)
            Obx(() {
              final master = azan.master.value;
              final on = master && azan.enabled[name] == true;
              return Opacity(
                opacity: master ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !master,
                  child: _GoldSwitch(value: on, onChanged: (_) => azan.togglePrayer(name)),
                ),
              );
            })
          else
            SizedBox(
              width: 52,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withOpacity(0.35),
              ),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: passed ? 0.65 : 1,
      child: Padding(padding: const EdgeInsets.only(bottom: 10), child: card),
    );
  }
}

// ═════════════════════════════ SETTINGS SHEET ═════════════════════════════

class _AzanSheet extends StatelessWidget {
  const _AzanSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? MejlisPalette.gold : MejlisPalette.goldDark;
    final azan = AzanController.to;
    final islamic = IslamicController.to;
    final maxH = MediaQuery.of(context).size.height * 0.9;

    Widget heading(String t) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: _SectionTitle(title: t, scheme: scheme),
    );

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: MejlisPalette.gold.withOpacity(0.5), width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                azanTr('azanSettings', 'Azan settings'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),

              // ── voices ──
              heading(azanTr('azanVoice', 'Azan voice')),
              for (final v in kAzanVoices)
                Obx(() {
                  final selected = azan.sound.value == v.key;
                  final playing = azan.previewing.value == v.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => azan.setSound(v.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? MejlisPalette.gold.withOpacity(0.14)
                              : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? MejlisPalette.gold
                                : MejlisPalette.gold.withOpacity(0.18),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected ? accent : scheme.onSurfaceVariant,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.label,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    v.subtitle,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: azanTr('preview', 'Preview'),
                              onPressed: () => azan.preview(v.key),
                              icon: Icon(
                                playing
                                    ? Icons.stop_circle_rounded
                                    : Icons.play_circle_fill_rounded,
                                size: 30,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              // ── fajr voice ──
              heading(azanTr('azanFajrVoice', 'Fajr voice')),
              Obx(
                    () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in kAzanVoices)
                      ChoiceChip(
                        label: Text(v.label),
                        selected: azan.fajrSound.value == v.key,
                        selectedColor: MejlisPalette.gold.withOpacity(0.3),
                        onSelected: (_) => azan.setFajrSound(v.key),
                      ),
                  ],
                ),
              ),

              // ── test ──
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: azan.testAzan,
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(azanTr('azanTestBtn', 'Test azan now')),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      azanTr('azanSilenceNote',
                          'The azan stops when you open the notification panel or press the power or volume key.'),
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),

              // ── calculation ──
              heading(azanTr('calcMethod', 'Calculation method')),
              Obx(() {
                final v = islamic.calculationMethod.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MejlisPalette.gold.withOpacity(0.25)),
                  ),
                  child: DropdownButton<int>(
                    value: _calcMethods.containsKey(v) ? v : 3,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      for (final e in _calcMethods.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (m) {
                      if (m != null) islamic.setCalculationMethod(m);
                    },
                  ),
                );
              }),
              heading(azanTr('asrSchool', 'Asr calculation')),
              Obx(
                    () => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text(azanTr('asrStandard', 'Standard'))),
                      ButtonSegment(value: 1, label: Text(azanTr('asrHanafi', 'Hanafi'))),
                    ],
                    selected: {islamic.asrSchool.value},
                    onSelectionChanged: (s) => islamic.setAsrSchool(s.first),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════ SKELETON ═════════════════════════════

class _Skeleton extends StatefulWidget {
  final ColorScheme scheme;
  final bool isDark;
  const _Skeleton({required this.scheme, required this.isDark});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = MejlisPalette.gold.withOpacity(0.22);

    Widget box(double h, {double r = 18}) => Container(
      height: h,
      decoration: BoxDecoration(color: shape, borderRadius: BorderRadius.circular(r)),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.45 + 0.55 * _c.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            children: [
              box(64, r: 20),
              const SizedBox(height: 14),
              box(150, r: 30),
              const SizedBox(height: 14),
              box(70, r: 22),
              const SizedBox(height: 20),
              for (int i = 0; i < 6; i++) ...[
                box(64, r: 20),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}