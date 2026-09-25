import 'package:abushakir/abushakir.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hijri/hijri_calendar.dart';

import '../controllers/hijri_calender_controller.dart';

enum CalendarType { gregorian, hijri, ethiopian }

class HijriDateConverterSheet extends StatelessWidget {
  const HijriDateConverterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const HijriDateConverterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => const _ConverterBody();
}

class _ConverterBody extends StatefulWidget {
  const _ConverterBody();

  @override
  State<_ConverterBody> createState() => _ConverterBodyState();
}

class _ConverterBodyState extends State<_ConverterBody> {
  final HijriCalendarController controller = Get.find<HijriCalendarController>();

  CalendarType _selectedSource = CalendarType.gregorian;

  DateTime _pickedGregorian = DateTime.now();

  // Hijri state
  int _pickedHYear = 1445;
  int _pickedHMonth = 1;
  int _pickedHDay = 1;

  // Ethiopian state
  int _pickedEYear = 2016;
  int _pickedEMonth = 1;
  int _pickedEDay = 1;

  @override
  void initState() {
    super.initState();
    final today = HijriCalendar.fromDate(DateTime.now());
    _pickedHYear = today.hYear;
    _pickedHMonth = today.hMonth;
    _pickedHDay = today.hDay;

    final ethiopianToday = EtDatetime.now();
    _pickedEYear = ethiopianToday.year;
    _pickedEMonth = ethiopianToday.month;
    _pickedEDay = ethiopianToday.day;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            const SizedBox(height: 16),
            Text(
              'dateConverter'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 16),
            SegmentedButton<CalendarType>(
              segments: const [
                ButtonSegment(value: CalendarType.gregorian, label: Text('Gregorian')),
                ButtonSegment(value: CalendarType.hijri, label: Text('Hijri')),
                ButtonSegment(value: CalendarType.ethiopian, label: Text('Ethiopian')),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (s) => setState(() => _selectedSource = s.first),
            ),
            const SizedBox(height: 20),
            if (_selectedSource == CalendarType.gregorian) ..._buildGregorianInput(scheme),
            if (_selectedSource == CalendarType.hijri) ..._buildHijriInput(scheme),
            if (_selectedSource == CalendarType.ethiopian) ..._buildEthiopianInput(scheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGregorianInput(ColorScheme scheme) {
    final hResult = HijriCalendar.fromDate(_pickedGregorian);
    final monthName = 'hijriMonth${hResult.hMonth}'.tr;

    final etResult = EtDatetime.fromMillisecondsSinceEpoch(_pickedGregorian.millisecondsSinceEpoch);

    return [
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month_rounded),
        label: Text(
          '${_pickedGregorian.year}-${_pickedGregorian.month.toString().padLeft(2, '0')}-'
              '${_pickedGregorian.day.toString().padLeft(2, '0')}',
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _pickedGregorian,
            firstDate: DateTime(1938),
            lastDate: DateTime(2076),
          );
          if (picked != null) setState(() => _pickedGregorian = picked);
        },
      ),
      const SizedBox(height: 16),
      _resultCard(scheme, 'Hijri', '$monthName ${hResult.hDay}, ${hResult.hYear} ${'hijriAbbr'.tr}'),
      const SizedBox(height: 8),
      _resultCard(scheme, 'Ethiopian', '${etResult.monthGeez} ${etResult.day}, ${etResult.year} E.C.'),
    ];
  }

  List<Widget> _buildHijriInput(ColorScheme scheme) {
    final gResult = controller.gregorianFromHijri(_pickedHYear, _pickedHMonth, _pickedHDay);
    final etResult = EtDatetime.fromMillisecondsSinceEpoch(gResult.millisecondsSinceEpoch);

    return [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedHDay,
              decoration: _inputDecoration('day'.tr),
              items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
              onChanged: (v) => setState(() => _pickedHDay = v ?? _pickedHDay),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedHMonth,
              decoration: _inputDecoration('month'.tr),
              items: List.generate(
                12,
                    (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    'hijriMonth${i + 1}'.tr,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _pickedHMonth = v ?? _pickedHMonth),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedHYear,
              decoration: _inputDecoration('year'.tr),
              items: [
                for (int y = controller.todayHYear.value - 2; y <= controller.todayHYear.value + 3; y++)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _pickedHYear = v ?? _pickedHYear),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _resultCard(
        scheme,
        'Gregorian',
        '${gResult.year}-${gResult.month.toString().padLeft(2, '0')}-${gResult.day.toString().padLeft(2, '0')}',
      ),
      const SizedBox(height: 8),
      _resultCard(scheme, 'Ethiopian', '${etResult.monthGeez} ${etResult.day}, ${etResult.year} E.C.'),
    ];
  }

  List<Widget> _buildEthiopianInput(ColorScheme scheme) {
    final etDate = EtDatetime(year: _pickedEYear, month: _pickedEMonth, day: _pickedEDay);
    final gResult = DateTime.fromMillisecondsSinceEpoch(etDate.moment);
    final hResult = HijriCalendar.fromDate(gResult);
    final monthName = 'hijriMonth${hResult.hMonth}'.tr;

    return [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedEDay,
              decoration: _inputDecoration('day'.tr),
              items: List.generate(30, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
              onChanged: (v) => setState(() => _pickedEDay = v ?? _pickedEDay),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedEMonth,
              decoration: _inputDecoration('month'.tr),
              items: List.generate(
                13,
                    (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(
                    EtDatetime(year: _pickedEYear, month: i + 1, day: 1).monthGeez!,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _pickedEMonth = v ?? _pickedEMonth),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              value: _pickedEYear,
              decoration: _inputDecoration('year'.tr),
              items: [
                for (int y = EtDatetime.now().year - 2; y <= EtDatetime.now().year + 3; y++)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (v) => setState(() => _pickedEYear = v ?? _pickedEYear),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _resultCard(
        scheme,
        'Gregorian',
        '${gResult.year}-${gResult.month.toString().padLeft(2, '0')}-${gResult.day.toString().padLeft(2, '0')}',
      ),
      const SizedBox(height: 8),
      _resultCard(scheme, 'Hijri', '$monthName ${hResult.hDay}, ${hResult.hYear} ${'hijriAbbr'.tr}'),
    ];
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      border: const OutlineInputBorder(),
    );
  }

  Widget _resultCard(ColorScheme scheme, String title, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary.withOpacity(0.14), scheme.primary.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface)),
        ],
      ),
    );
  }
}