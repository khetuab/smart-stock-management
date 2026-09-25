class QuranAyah {
  final int number; // global ayah number (1-6236)
  final String text; // Uthmani Arabic text
  final int numberInSurah;
  final int juz;
  final int page;
  final int surahNumber;
  final String surahName; // Arabic name
  final String surahEnglishName;
  final String? translation;

  const QuranAyah({
    required this.number,
    required this.text,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    required this.surahNumber,
    required this.surahName,
    required this.surahEnglishName,
    this.translation,
  });

  QuranAyah copyWithTranslation(String? translation) {
    return QuranAyah(
      number: number,
      text: text,
      numberInSurah: numberInSurah,
      juz: juz,
      page: page,
      surahNumber: surahNumber,
      surahName: surahName,
      surahEnglishName: surahEnglishName,
      translation: translation,
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

class TranslationEdition {
  final String identifier;
  final String displayName;
  const TranslationEdition(this.identifier, this.displayName);
}

/// A small, curated set of well-known translation editions available on the
/// AlQuran Cloud API. Add more identifiers from
/// https://api.alquran.cloud/v1/edition?type=translation as needed.
const List<TranslationEdition> availableTranslations = [
  TranslationEdition('en.sahih', 'English — Saheeh International'),
  TranslationEdition('en.pickthall', 'English — Pickthall'),
  TranslationEdition('en.yusufali', 'English — Yusuf Ali'),
  TranslationEdition('ur.jalandhry', 'Urdu — Jalandhry'),
  TranslationEdition('fr.hamidullah', 'French — Hamidullah'),
  TranslationEdition('id.indonesian', 'Indonesian — Kemenag'),
];