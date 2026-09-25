import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/hijri_event_model.dart';
import '../../controllers/hijri_calender_controller.dart';
import '../../widgets/hijri_convert.dart';
import '../../widgets/hijriadjustsheet.dart';
import '../../widgets/hijriday_sheet.dart';
import '../../widgets/islamic_sliver_appbar.dart';

/// Main Hijri calendar screen: month grid, event markers, upcoming
/// occasions, and quick access to the date converter + day-adjustment
/// sheets. Built on top of [HijriCalendarController], [IslamicSliverAppBar],
/// [HijriDayDetailSheet], [HijriAdjustmentSheet], and [HijriDateConverterSheet].
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

    return Scaffold(
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HijriDateConverterSheet.show(context),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: Text('dateConverter'.tr),
      ),
      body: CustomScrollView(
        slivers: [
          IslamicSliverAppBar(
            title: 'hijriCalendar'.tr,
            icon: Icons.calendar_month_rounded,
            actions: [
              IconButton(
                tooltip: 'calendarAdjustment'.tr,
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => HijriAdjustmentSheet.show(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _monthHeader(context, scheme),
                  const SizedBox(height: 16),
                  _weekdayRow(scheme),
                  const SizedBox(height: 6),
                  _monthGrid(context, scheme),
                  const SizedBox(height: 24),
                  _upcomingSection(context, scheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthHeader(BuildContext context, ColorScheme scheme) {
    return Obx(() {
      final monthName = hijriMonthNameKeys[controller.displayedMonth.value - 1].tr;
      final isCurrentMonth = controller.displayedYear.value == controller.todayHYear.value &&
          controller.displayedMonth.value == controller.todayHMonth.value;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: controller.previousMonth,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$monthName ${controller.displayedYear.value} ${'hijriAbbr'.tr}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface),
                ),
                if (!isCurrentMonth)
                  TextButton(
                    onPressed: controller.goToToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('today'.tr, style: TextStyle(fontSize: 12, color: scheme.primary)),
                  ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: controller.nextMonth,
          ),
        ],
      );
    });
  }

  Widget _weekdayRow(ColorScheme scheme) {
    return Row(
      children: [
        for (final key in _weekdayShort)
          Expanded(
            child: Center(
              child: Text(
                key.tr.substring(0, key.tr.length >= 2 ? 2 : key.tr.length),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _monthGrid(BuildContext context, ColorScheme scheme) {
    return Obx(() {
      final cells = controller.gridCells;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cells.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final cell = cells[index];
          if (cell == null) return const SizedBox.shrink();

          final hasEvent = cell.events.isNotEmpty;
          final isHoliday = cell.events.any((e) => e.isHoliday);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => HijriDayDetailSheet.show(
              context,
              cell,
              controller.displayedMonth.value,
              controller.displayedYear.value,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cell.isToday
                    ? scheme.primary
                    : isHoliday
                    ? scheme.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: hasEvent && !cell.isToday
                    ? Border.all(color: scheme.primary.withOpacity(0.4))
                    : null,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${cell.hijriDay}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: cell.isToday ? FontWeight.bold : FontWeight.w500,
                      color: cell.isToday ? Colors.white : scheme.onSurface,
                    ),
                  ),
                  if (hasEvent)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cell.isToday ? Colors.white : scheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _upcomingSection(BuildContext context, ColorScheme scheme) {
    return Obx(() {
      final upcoming = controller.upcomingOccasions;
      if (upcoming.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'upcomingOccasions'.tr,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),
          const SizedBox(height: 10),
          for (final occasion in upcoming) _upcomingTile(scheme, occasion),
        ],
      );
    });
  }

  Widget _upcomingTile(ColorScheme scheme, UpcomingOccasion occasion) {
    final date = occasion.gregorianDate;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              occasion.event.isHoliday ? Icons.celebration_rounded : Icons.star_rounded,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  occasion.event.nameKey.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            occasion.daysUntil == 0 ? 'today'.tr : '${occasion.daysUntil}${'daysAbbr'.tr}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}