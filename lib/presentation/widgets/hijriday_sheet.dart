import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/hijri_calender_controller.dart';

class HijriDayDetailSheet extends StatelessWidget {
  final HijriDayCell cell;
  final int hijriMonth;
  final int hijriYear;

  const HijriDayDetailSheet({
    super.key,
    required this.cell,
    required this.hijriMonth,
    required this.hijriYear,
  });

  static void show(BuildContext context, HijriDayCell cell, int hijriMonth, int hijriYear) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HijriDayDetailSheet(cell: cell, hijriMonth: hijriMonth, hijriYear: hijriYear),
    );
  }

  static const _weekdayKeys = [
    'weekdayMon',
    'weekdayTue',
    'weekdayWed',
    'weekdayThu',
    'weekdayFri',
    'weekdaySat',
    'weekdaySun',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthName = 'hijriMonth$hijriMonth'.tr;
    final weekdayName = _weekdayKeys[cell.gregorianDate.weekday - 1].tr;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${cell.hijriDay}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthName $hijriYear ${'hijriAbbr'.tr}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$weekdayName · ${cell.gregorianDate.year}-'
                            '${cell.gregorianDate.month.toString().padLeft(2, '0')}-'
                            '${cell.gregorianDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cell.events.isNotEmpty) ...[
              const SizedBox(height: 20),
              Divider(color: scheme.outlineVariant.withOpacity(0.4)),
              const SizedBox(height: 12),
              for (final event in cell.events)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        event.isHoliday ? Icons.celebration_rounded : Icons.star_rounded,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event.nameKey.tr,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}