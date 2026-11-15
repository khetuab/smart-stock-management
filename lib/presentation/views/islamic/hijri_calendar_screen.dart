
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/hijri_event_model.dart';
import '../../controllers/hijri_calender_controller.dart';
import '../../widgets/hijri_convert.dart';
import '../../widgets/hijriadjustsheet.dart';
import '../../widgets/hijriday_sheet.dart';
import '../../widgets/mejlis_kit.dart';

// Premium Hijri calendar screen.
class HijriCalendarScreen extends GetView<HijriCalendarController> {
  const HijriCalendarScreen({super.key});

  static const _weekdayShort = [
    'weekdaySun',
    'weekdayMon',
    'weekdayTue',
    'weekdayWed',
    'weekdayThu',
    'weekdayFri',
    'weekdaySat',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HijriDateConverterSheet.show(context),
        elevation: 5,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text('dateConverter'.tr),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Premium expandable app bar ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: scheme.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                tooltip: 'calendarAdjustment'.tr,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                ),
                onPressed: () => HijriAdjustmentSheet.show(context),
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
                'hijriCalendar'.tr,
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
              background: const MejlisHeaderBackground(
                showSkyline: false,
              ),
            ),
          ),

          // ── Calendar content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _monthHeader(context, scheme, isDark),

                  const SizedBox(height: 24),

                  _calendarSectionTitle(
                    'calendar'.tr,
                    Icons.calendar_month_rounded,
                    scheme,
                  ),

                  const SizedBox(height: 14),

                  _weekdayRow(scheme),

                  const SizedBox(height: 10),

                  _monthGrid(context, scheme, isDark),

                  const SizedBox(height: 28),

                  _upcomingSection(context, scheme, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── MONTH HEADER ─────────────────────

  Widget _monthHeader(
      BuildContext context,
      ColorScheme scheme,
      bool isDark,
      ) {
    return Obx(() {
      final month = controller.displayedMonth.value;
      final year = controller.displayedYear.value;

      final monthName = hijriMonthNameKeys[month - 1].tr;

      final isCurrentMonth =
          year == controller.todayHYear.value &&
              month == controller.todayHMonth.value;

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
              scheme.surfaceContainerHigh,
              scheme.surfaceContainer,
            ]
                : [
              Colors.white,
              scheme.primary.withOpacity(0.035),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.primary.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.08 : 0.035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            _monthArrow(
              icon: Icons.chevron_left_rounded,
              scheme: scheme,
              onTap: controller.previousMonth,
            ),

            Expanded(
              child: Column(
                children: [
                  Text(
                    monthName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$year ${'hijriAbbr'.tr}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  if (!isCurrentMonth) ...[
                    const SizedBox(height: 9),

                    GestureDetector(
                      onTap: controller.goToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'today'.tr,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            _monthArrow(
              icon: Icons.chevron_right_rounded,
              scheme: scheme,
              onTap: controller.nextMonth,
            ),
          ],
        ),
      );
    });
  }

  Widget _monthArrow({
    required IconData icon,
    required ColorScheme scheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: scheme.primary.withOpacity(0.09),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: scheme.primary,
            size: 25,
          ),
        ),
      ),
    );
  }

  // ───────────────────── SECTION TITLE ─────────────────────

  Widget _calendarSectionTitle(
      String title,
      IconData icon,
      ColorScheme scheme,
      ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ───────────────────── WEEKDAYS ─────────────────────

  Widget _weekdayRow(ColorScheme scheme) {
    return Row(
      children: [
        for (int i = 0; i < _weekdayShort.length; i++)
          Expanded(
            child: Center(
              child: Text(
                _weekdayShort[i]
                    .tr
                    .substring(
                  0,
                  _weekdayShort[i].tr.length >= 2
                      ? 2
                      : _weekdayShort[i].tr.length,
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: i == 5
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────── MONTH GRID ─────────────────────

  Widget _monthGrid(
      BuildContext context,
      ColorScheme scheme,
      bool isDark,
      ) {
    return Obx(() {
      final cells = controller.gridCells;
      final month = controller.displayedMonth.value;
      final year = controller.displayedYear.value;

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerLow
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.05 : 0.025),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 4,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final cell = cells[index];

            if (cell == null) {
              return const SizedBox.shrink();
            }

            final hasEvent = cell.events.isNotEmpty;
            final isHoliday = cell.events.any((e) => e.isHoliday);
            final isToday = cell.isToday;

            return _DayCell(
              day: cell.hijriDay,
              isToday: isToday,
              hasEvent: hasEvent,
              isHoliday: isHoliday,
              scheme: scheme,
              onTap: () => HijriDayDetailSheet.show(
                context,
                cell,
                month,
                year,
              ),
            );
          },
        ),
      );
    });
  }

  // ───────────────────── UPCOMING OCCASIONS ─────────────────────

  Widget _upcomingSection(
      BuildContext context,
      ColorScheme scheme,
      bool isDark,
      ) {
    return Obx(() {
      final upcoming = controller.upcomingOccasions;

      if (upcoming.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _calendarSectionTitle(
            'upcomingOccasions'.tr,
            Icons.auto_awesome_rounded,
            scheme,
          ),

          const SizedBox(height: 15),

          for (int i = 0; i < upcoming.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _upcomingTile(
                scheme,
                upcoming[i],
                isDark,
              ),
            ),
        ],
      );
    });
  }

  Widget _upcomingTile(
      ColorScheme scheme,
      UpcomingOccasion occasion,
      bool isDark,
      ) {
    final date = occasion.gregorianDate;

    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final isHoliday = occasion.event.isHoliday;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerLow
            : Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.04 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withOpacity(0.15),
                  scheme.primary.withOpacity(0.055),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isHoliday
                  ? Icons.celebration_rounded
                  : Icons.star_rounded,
              color: scheme.primary,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occasion.event.nameKey.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              occasion.daysUntil == 0
                  ? 'today'.tr
                  : '${occasion.daysUntil}${'daysAbbr'.tr}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ DAY CELL ═════════════════════════════

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool hasEvent;
  final bool isHoliday;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEvent,
    required this.isHoliday,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isToday
        ? scheme.primary
        : isHoliday
        ? scheme.primary.withOpacity(0.12)
        : hasEvent
        ? scheme.primary.withOpacity(0.045)
        : Colors.transparent;

    final foreground = isToday
        ? Colors.white
        : scheme.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: isToday
                ? Border.all(
              color: scheme.primary,
              width: 1.5,
            )
                : hasEvent
                ? Border.all(
              color: scheme.primary.withOpacity(0.28),
            )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday
                      ? FontWeight.w900
                      : FontWeight.w600,
                  color: foreground,
                ),
              ),

              const SizedBox(height: 4),

              if (hasEvent)
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday
                        ? Colors.white
                        : scheme.primary,
                  ),
                )
              else
                const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
