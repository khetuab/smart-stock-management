import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/hijri_event_model.dart';

class HijriDayCell {
  final int hijriDay;
  final DateTime gregorianDate;
  final bool isToday;
  final List<HijriEvent> events;

  const HijriDayCell({
    required this.hijriDay,
    required this.gregorianDate,
    required this.isToday,
    required this.events,
  });
}

class UpcomingOccasion {
  final HijriEvent event;
  final DateTime gregorianDate;
  final int daysUntil;

  const UpcomingOccasion({
    required this.event,
    required this.gregorianDate,
    required this.daysUntil,
  });
}

class HijriCalendarController extends GetxController {
  static const String _adjustmentPrefsKey = 'hijri_day_adjustment';

  final HijriCalendar _converter = HijriCalendar();

  final RxInt displayedYear = 0.obs;
  final RxInt displayedMonth = 0.obs;

  final RxInt todayHYear = 0.obs;
  final RxInt todayHMonth = 0.obs;
  final RxInt todayHDay = 0.obs;

  // Local moon-sighting adjustment: some regions announce a day earlier
  // or later than the tabular calculation. Persisted so it survives restarts.
  final RxInt dayAdjustment = 0.obs;

  final RxList<HijriDayCell?> gridCells = <HijriDayCell?>[].obs;
  final RxList<UpcomingOccasion> upcomingOccasions = <UpcomingOccasion>[].obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    dayAdjustment.value = _prefs?.getInt(_adjustmentPrefsKey) ?? 0;
    _refreshToday();
    displayedYear.value = todayHYear.value;
    displayedMonth.value = todayHMonth.value;
    _rebuildGrid();
    _rebuildUpcoming();
  }

  void _refreshToday() {
    final adjustedNow = DateTime.now().add(Duration(days: dayAdjustment.value));
    final hToday = HijriCalendar.fromDate(adjustedNow);
    todayHYear.value = hToday.hYear;
    todayHMonth.value = hToday.hMonth;
    todayHDay.value = hToday.hDay;
  }

  /// The Gregorian date for Hijri (year, month, day 1), used as the anchor
  /// for laying out a month grid and for computing month length by
  /// diffing against the next month's first day — this avoids depending on
  /// any undocumented internal state of the conversion library.
  DateTime _firstOfHijriMonth(int year, int month) => _converter.hijriToGregorian(year, month, 1);

  void _rebuildGrid() {
    final year = displayedYear.value;
    final month = displayedMonth.value;

    final firstDay = _firstOfHijriMonth(year, month);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final firstOfNext = _firstOfHijriMonth(nextYear, nextMonth);
    final daysInMonth = firstOfNext.difference(firstDay).inDays;

    // Grid starts on Sunday.
    final leadingBlanks = firstDay.weekday % 7; // DateTime.weekday: Mon=1..Sun=7

    final cells = <HijriDayCell?>[
      for (int i = 0; i < leadingBlanks; i++) null,
      for (int d = 1; d <= daysInMonth; d++)
        HijriDayCell(
          hijriDay: d,
          gregorianDate: firstDay.add(Duration(days: d - 1)),
          isToday: year == todayHYear.value && month == todayHMonth.value && d == todayHDay.value,
          events: islamicOccasions.where((e) => e.hijriMonth == month && e.hijriDay == d).toList(),
        ),
    ];

    gridCells.assignAll(cells);
  }

  void _rebuildUpcoming() {
    final results = <UpcomingOccasion>[];
    final adjustedNow = DateTime.now().add(Duration(days: dayAdjustment.value));
    final todayDateOnly = DateTime(adjustedNow.year, adjustedNow.month, adjustedNow.day);

    for (final event in islamicOccasions) {
      // Try this Hijri year first; if it's already passed, use next year.
      var gDate = _converter.hijriToGregorian(todayHYear.value, event.hijriMonth, event.hijriDay);
      if (gDate.isBefore(todayDateOnly)) {
        gDate = _converter.hijriToGregorian(todayHYear.value + 1, event.hijriMonth, event.hijriDay);
      }
      final daysUntil = gDate.difference(todayDateOnly).inDays;
      results.add(UpcomingOccasion(event: event, gregorianDate: gDate, daysUntil: daysUntil));
    }

    results.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    upcomingOccasions.assignAll(results.take(5));
  }

  void nextMonth() {
    if (displayedMonth.value == 12) {
      displayedMonth.value = 1;
      displayedYear.value++;
    } else {
      displayedMonth.value++;
    }
    _rebuildGrid();
  }

  void previousMonth() {
    if (displayedMonth.value == 1) {
      displayedMonth.value = 12;
      displayedYear.value--;
    } else {
      displayedMonth.value--;
    }
    _rebuildGrid();
  }

  void goToMonth(int year, int month) {
    displayedYear.value = year;
    displayedMonth.value = month;
    _rebuildGrid();
  }

  void goToToday() {
    displayedYear.value = todayHYear.value;
    displayedMonth.value = todayHMonth.value;
    _rebuildGrid();
  }

  Future<void> setDayAdjustment(int value) async {
    dayAdjustment.value = value;
    await _prefs?.setInt(_adjustmentPrefsKey, value);
    _refreshToday();
    _rebuildGrid();
    _rebuildUpcoming();
  }

  // ---- Converter helpers (used by the date-converter sheet) ----

  HijriCalendar hijriFromGregorian(DateTime date) => HijriCalendar.fromDate(date);

  DateTime gregorianFromHijri(int year, int month, int day) => _converter.hijriToGregorian(year, month, day);
}