class HijriEvent {
  final int hijriMonth; // 1-12
  final int hijriDay; // 1-30
  final String nameKey; // translation key
  final bool isHoliday; // true for the two Eids

  const HijriEvent({
    required this.hijriMonth,
    required this.hijriDay,
    required this.nameKey,
    this.isHoliday = false,
  });
}

/// A curated set of the most widely-recognized fixed dates on the Hijri
/// calendar. These are commonly referenced markers, not religious rulings —
/// some observances (e.g. Mawlid, the exact night of Laylat al-Qadr) vary
/// by region and school of thought, and actual local observance can shift
/// by a day depending on moon sighting.
const List<HijriEvent> islamicOccasions = [
  HijriEvent(hijriMonth: 1, hijriDay: 1, nameKey: 'occasionHijriNewYear'),
  HijriEvent(hijriMonth: 1, hijriDay: 10, nameKey: 'occasionAshura'),
  HijriEvent(hijriMonth: 7, hijriDay: 27, nameKey: 'occasionIsraMiraj'),
  HijriEvent(hijriMonth: 9, hijriDay: 1, nameKey: 'occasionRamadanStart'),
  HijriEvent(hijriMonth: 9, hijriDay: 27, nameKey: 'occasionLaylatulQadr'),
  HijriEvent(hijriMonth: 10, hijriDay: 1, nameKey: 'occasionEidalFitr', isHoliday: true),
  HijriEvent(hijriMonth: 12, hijriDay: 9, nameKey: 'occasionDayOfArafah'),
  HijriEvent(hijriMonth: 12, hijriDay: 10, nameKey: 'occasionEidalAdha', isHoliday: true),
];

const List<String> hijriMonthNameKeys = [
  'hijriMonth1',
  'hijriMonth2',
  'hijriMonth3',
  'hijriMonth4',
  'hijriMonth5',
  'hijriMonth6',
  'hijriMonth7',
  'hijriMonth8',
  'hijriMonth9',
  'hijriMonth10',
  'hijriMonth11',
  'hijriMonth12',
];