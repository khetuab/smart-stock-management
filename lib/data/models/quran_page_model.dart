class QuranAyah {
  final int number; // global ayah number (1-6236) — also the audio CDN index
  final String text; // Uthmani Arabic text
  final int numberInSurah;
  final int juz;
  final int page;
  final int surahNumber;
  final String surahName; // Arabic name
  final String surahEnglishName;

  /// edition identifier (en.sahih / am.sadiq / ar.muyassar) -> translation
  final Map<String, String> translations;

  const QuranAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    this.translations = const {},
  });

  /// Backward-compatible single translation accessor.
  String? get translation =>
      translations.isEmpty ? null : translations.values.first;

  QuranAyah copyWithTranslation(String? translation) {
    final next = Map<String, String>.from(translations);
    if (translation != null && next.isNotEmpty) {
      next[next.keys.first] = translation;
    }
    return QuranAyah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      page: page,
      surahNumber: surahNumber,
      surahName: surahName,
      surahEnglishName: surahEnglishName,
      translations: next,
    );
  }
}

/// Metadata for one of the 114 surahs, used to populate the surah picker
/// without needing to fetch its full ayah text first.
class QuranSurahMeta {
  final int number;
  final String name; // Arabic name, e.g. "الفاتحة"
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const QuranSurahMeta({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory QuranSurahMeta.fromJson(Map<String, dynamic> json) => QuranSurahMeta(
    number: json['number'] as int,
    name: json['name'] as String,
    englishName: json['englishName'] as String,
    englishNameTranslation: json['englishNameTranslation'] as String,
    numberOfAyahs: json['numberOfAyahs'] as int,
    revelationType: json['revelationType'] as String,
  );
}

/// One Quran translation language offered in the reader — verified
/// identifiers on the AlQuran Cloud API.
class TranslationEdition {
  final String identifier;
  final String displayName;
  final String nativeLabel; // shown on the reader's language chips
  const TranslationEdition(this.identifier, this.displayName, this.nativeLabel);
}

const List<TranslationEdition> availableTranslations = [
  TranslationEdition('en.sahih', 'English — Saheeh International', 'English'),
  TranslationEdition('am.sadiq', 'Amharic — ሳዲቅ & ሳኒ ሐቢብ', 'አማርኛ'),
  TranslationEdition('ar.muyassar', 'Arabic — Muyassar Tafsir', 'العربية'),
];

/// Reciters offered for audio recitation (all verified audio editions on
/// the islamic.network CDN). Alafasy is the house default.
class ReciterEdition {
  final String identifier;
  final String displayName;
  const ReciterEdition(this.identifier, this.displayName);
}

const List<ReciterEdition> availableReciters = [
  ReciterEdition('ar.alafasy', 'Mishary Alafasy'),
  ReciterEdition('ar.abdulbasitmurattal', 'Abdul Basit (Murattal)'),
  ReciterEdition('ar.husary', 'Al-Husary'),
  ReciterEdition('ar.husarymujawwad', 'Al-Husary (Mujawwad)'),
  ReciterEdition('ar.minshawi', 'Al-Minshawi'),
  ReciterEdition('ar.minshawimujawwad', 'Al-Minshawi (Mujawwad)'),
  ReciterEdition('ar.abdurrahmaansudais', 'Abdurrahman As-Sudais'),
  ReciterEdition('ar.shaatree', 'Abu Bakr Ash-Shaatree'),
  ReciterEdition('ar.mahermuaiqly', 'Maher Al-Muaiqly'),
  ReciterEdition('ar.saoodshuraym', 'Saud Ash-Shuraym'),
  ReciterEdition('ar.hudhaify', 'Ali Al-Hudhaify'),
  ReciterEdition('ar.ahmedajamy', 'Ahmad Al-Ajamy'),
  ReciterEdition('ar.muhammadayyoub', 'Muhammad Ayyub'),
  ReciterEdition('ar.muhammadjibreel', 'Muhammad Jibreel'),
];
