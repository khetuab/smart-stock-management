import 'dart:math' as math;

/// Data models for the page-based ("mushaf") Quran reader.
///
/// Kept separate from your existing `quran_page_model.dart` (used by the
/// continuous surah-by-surah reader) on purpose, so this feature drops into
/// an existing project without touching or depending on whatever shape
/// your current models already have.

// ---------------------------------------------------------------------
// Ayah
// ---------------------------------------------------------------------

/// One ayah as it appears on a mushaf page.
class MushafAyah {
  final int surahNumber;
  final String surahNameArabic;
  final String surahNameEnglish;
  final int numberInSurah;
  final int globalAyahNumber;
  final String text;
  final String? translation;
  final int juz;
  final int page;
  final bool isSurahStart;

  const MushafAyah({
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameEnglish,
    required this.numberInSurah,
    required this.globalAyahNumber,
    required this.text,
    required this.juz,
    required this.page,
    required this.isSurahStart,
    this.translation,
  });

  factory MushafAyah.fromAlQuranCloudJson(Map<String, dynamic> json) {
    final surah = json['surah'] as Map<String, dynamic>? ?? const {};
    final numberInSurah = json['numberInSurah'] as int? ?? 0;
    return MushafAyah(
      surahNumber: surah['number'] as int? ?? 0,
      surahNameArabic: surah['name'] as String? ?? '',
      surahNameEnglish: surah['englishName'] as String? ?? '',
      numberInSurah: numberInSurah,
      globalAyahNumber: json['number'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      juz: json['juz'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      isSurahStart: numberInSurah == 1,
    );
  }

  MushafAyah copyWithTranslation(String? value) => MushafAyah(
    surahNumber: surahNumber,
    surahNameArabic: surahNameArabic,
    surahNameEnglish: surahNameEnglish,
    numberInSurah: numberInSurah,
    globalAyahNumber: globalAyahNumber,
    text: text,
    juz: juz,
    page: page,
    isSurahStart: isSurahStart,
    translation: value,
  );
}

// ---------------------------------------------------------------------
// Lines / Page
// ---------------------------------------------------------------------

enum MushafLineKind { surahBanner, bismillah, text, blank }

/// Reading color theme for the mushaf pages.
enum MushafReadingTheme { light, sepia, night }

class MushafLineSegment {
  final MushafAyah ayah;
  final String words;
  final bool endsAyahHere;

  const MushafLineSegment({
    required this.ayah,
    required this.words,
    required this.endsAyahHere,
  });
}

class MushafLine {
  final MushafLineKind kind;
  final List<MushafLineSegment> segments;
  final String? bannerText;

  const MushafLine.text(this.segments)
      : kind = MushafLineKind.text,
        bannerText = null;

  const MushafLine.banner(this.bannerText)
      : kind = MushafLineKind.surahBanner,
        segments = const [];

  const MushafLine.bismillah()
      : kind = MushafLineKind.bismillah,
        segments = const [],
        bannerText = null;

  const MushafLine.blank()
      : kind = MushafLineKind.blank,
        segments = const [],
        bannerText = null;
}

/// A fully laid-out mushaf page: always exactly [linesPerPage] lines
/// (short pages — e.g. page 1, page 604 — are padded with blank lines).
class MushafPage {
  static const int linesPerPage = 15;
  static const int totalPages = 604;

  final int pageNumber;
  final int juzNumber;
  final List<MushafAyah> ayahs;
  final List<MushafLine> lines;

  const MushafPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.ayahs,
    required this.lines,
  });
}

// ---------------------------------------------------------------------
// Layout algorithm
// ---------------------------------------------------------------------

class _Token {
  final MushafAyah ayah;
  final String word;
  bool isAyahEnd;
  _Token({required this.ayah, required this.word, this.isAyahEnd = false});
}

enum _BlockKind { words, banner, bismillah }

class _Block {
  final _BlockKind kind;
  final List<_Token> tokens;
  final String? bannerText;

  _Block.words(this.tokens)
      : kind = _BlockKind.words,
        bannerText = null;
  _Block.banner(this.bannerText)
      : kind = _BlockKind.banner,
        tokens = const [];
  _Block.bismillah()
      : kind = _BlockKind.bismillah,
        tokens = const [],
        bannerText = null;
}

const List<String> _basmalahVariants = [
  'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
];

/// Splits the ayahs of one mushaf page into exactly [MushafPage.linesPerPage]
/// lines.
///
/// WHAT THIS DOES AND DOESN'T DO:
/// Every free, keyless Quran API (Al-Quran Cloud included) can tell you
/// *which ayahs belong on page N* of the standard 604-page Madani mushaf —
/// that boundary is exact and matches a printed mushaf. None of them can
/// tell you *which words sit on which of that page's 15 printed lines*,
/// because that data is tied to the Saudi King Fahd Complex's proprietary
/// per-page glyph fonts (QCF), which aren't freely redistributable.
///
/// So: page *boundaries* here are exact. Line *breaks within* a page are a
/// deliberate, even, word-count approximation — visually a real 15-line
/// mushaf page, but not a pixel-identical reproduction of one specific
/// printed edition. Surah banners and the Bismillah are detected and given
/// their own centered line, same as in print.
List<MushafLine> layOutPageLines(List<MushafAyah> ayahs) {
  if (ayahs.isEmpty) {
    return List.generate(MushafPage.linesPerPage, (_) => const MushafLine.blank());
  }

  final blocks = <_Block>[];
  List<_Token> currentRun = [];

  void flushRun() {
    if (currentRun.isNotEmpty) {
      blocks.add(_Block.words(currentRun));
      currentRun = [];
    }
  }

  for (final ayah in ayahs) {
    String text = ayah.text.trim();

    if (ayah.isSurahStart) {
      flushRun();
      blocks.add(_Block.banner(ayah.surahNameEnglish));

      if (ayah.surahNumber != 9) {
        if (ayah.surahNumber == 1) {
          // Ayah 1 of Al-Fatihah *is* the Bismillah.
          blocks.add(_Block.bismillah());
          text = '';
        } else {
          for (final v in _basmalahVariants) {
            if (text.startsWith(v)) {
              blocks.add(_Block.bismillah());
              text = text.substring(v.length).trim();
              break;
            }
          }
        }
      }
    }

    if (text.isEmpty) continue;
    for (final w in text.split(RegExp(r'\s+'))) {
      if (w.isEmpty) continue;
      currentRun.add(_Token(ayah: ayah, word: w));
    }
    if (currentRun.isNotEmpty) currentRun.last.isAyahEnd = true;
  }
  flushRun();

  final forcedCount = blocks.where((b) => b.kind != _BlockKind.words).length;
  final wordBlocks = blocks.where((b) => b.kind == _BlockKind.words).toList();
  final totalWords = wordBlocks.fold<int>(0, (sum, b) => sum + b.tokens.length);
  final availableTextLines =
  (MushafPage.linesPerPage - forcedCount).clamp(1, MushafPage.linesPerPage);

  final lines = <MushafLine>[];
  int textLinesUsed = 0;

  for (final block in blocks) {
    if (block.kind == _BlockKind.banner) {
      lines.add(MushafLine.banner(block.bannerText));
      continue;
    }
    if (block.kind == _BlockKind.bismillah) {
      lines.add(const MushafLine.bismillah());
      continue;
    }

    final remainingSlots = (availableTextLines - textLinesUsed).clamp(1, availableTextLines);
    final linesForThisBlock = totalWords == 0
        ? 1
        : math
        .max(1, (block.tokens.length / totalWords * availableTextLines).round())
        .clamp(1, remainingSlots);

    final perLine = (block.tokens.length / linesForThisBlock).ceil().clamp(1, block.tokens.length);
    int i = 0;
    for (int lineNo = 0; lineNo < linesForThisBlock && i < block.tokens.length; lineNo++) {
      final isLast = lineNo == linesForThisBlock - 1;
      final end = isLast ? block.tokens.length : math.min(i + perLine, block.tokens.length);
      lines.add(MushafLine.text(_toSegments(block.tokens.sublist(i, end))));
      textLinesUsed++;
      i = end;
    }
  }

  while (lines.length < MushafPage.linesPerPage) {
    lines.add(const MushafLine.blank());
  }
  if (lines.length > MushafPage.linesPerPage) {
    // Extremely rare fallback (a page with many short surah starts): merge
    // the overflow into the final line rather than silently dropping text.
    final overflow = lines.sublist(MushafPage.linesPerPage - 1);
    final merged = overflow.expand((l) => l.segments).toList();
    lines.removeRange(MushafPage.linesPerPage - 1, lines.length);
    lines.add(MushafLine.text(merged));
  }

  return lines;
}

List<MushafLineSegment> _toSegments(List<_Token> tokens) {
  final segments = <MushafLineSegment>[];
  MushafAyah? currentAyah;
  final buffer = <String>[];
  bool endsHere = false;

  void flush() {
    if (currentAyah != null && buffer.isNotEmpty) {
      segments.add(MushafLineSegment(ayah: currentAyah!, words: buffer.join(' '), endsAyahHere: endsHere));
    }
    buffer.clear();
    endsHere = false;
  }

  for (final t in tokens) {
    if (currentAyah != null && t.ayah.globalAyahNumber != currentAyah!.globalAyahNumber) {
      flush();
    }
    currentAyah = t.ayah;
    buffer.add(t.word);
    if (t.isAyahEnd) endsHere = true;
  }
  flush();
  return segments;
}

// ---------------------------------------------------------------------
// Static reference data
// ---------------------------------------------------------------------

/// Standard juz-start pages for the 604-page Madani mushaf. Used as an
/// instant offline picker list; `QuranMushafService.fetchJuzStartPage`
/// confirms the true value for the active edition over the network and
/// falls back to this list if that call fails.
const List<int> standardJuzStartPages = [
  1, 22, 42, 62, 82, 102, 121, 142, 162, 182, //
  201, 222, 242, 262, 282, 302, 322, 342, 362, 382, //
  402, 422, 442, 462, 482, 502, 522, 542, 562, 582, //
];

class SurahNameEntry {
  final int number;
  final String arabic;
  final String english;
  const SurahNameEntry(this.number, this.arabic, this.english);
}

/// The 114 surah names, for instant display in the surah picker before
/// that surah's page data has been fetched.
const List<SurahNameEntry> quranSurahNames = [
  SurahNameEntry(1, 'الفاتحة', 'Al-Fatihah'),
  SurahNameEntry(2, 'البقرة', 'Al-Baqarah'),
  SurahNameEntry(3, 'آل عمران', 'Aali Imran'),
  SurahNameEntry(4, 'النساء', 'An-Nisa'),
  SurahNameEntry(5, 'المائدة', "Al-Ma'idah"),
  SurahNameEntry(6, 'الأنعام', "Al-An'am"),
  SurahNameEntry(7, 'الأعراف', "Al-A'raf"),
  SurahNameEntry(8, 'الأنفال', 'Al-Anfal'),
  SurahNameEntry(9, 'التوبة', 'At-Tawbah'),
  SurahNameEntry(10, 'يونس', 'Yunus'),
  SurahNameEntry(11, 'هود', 'Hud'),
  SurahNameEntry(12, 'يوسف', 'Yusuf'),
  SurahNameEntry(13, 'الرعد', "Ar-Ra'd"),
  SurahNameEntry(14, 'ابراهيم', 'Ibrahim'),
  SurahNameEntry(15, 'الحجر', 'Al-Hijr'),
  SurahNameEntry(16, 'النحل', 'An-Nahl'),
  SurahNameEntry(17, 'الإسراء', 'Al-Isra'),
  SurahNameEntry(18, 'الكهف', 'Al-Kahf'),
  SurahNameEntry(19, 'مريم', 'Maryam'),
  SurahNameEntry(20, 'طه', 'Taha'),
  SurahNameEntry(21, 'الأنبياء', 'Al-Anbiya'),
  SurahNameEntry(22, 'الحج', 'Al-Hajj'),
  SurahNameEntry(23, 'المؤمنون', "Al-Mu'minun"),
  SurahNameEntry(24, 'النور', 'An-Nur'),
  SurahNameEntry(25, 'الفرقان', 'Al-Furqan'),
  SurahNameEntry(26, 'الشعراء', "Ash-Shu'ara"),
  SurahNameEntry(27, 'النمل', 'An-Naml'),
  SurahNameEntry(28, 'القصص', 'Al-Qasas'),
  SurahNameEntry(29, 'العنكبوت', 'Al-Ankabut'),
  SurahNameEntry(30, 'الروم', 'Ar-Rum'),
  SurahNameEntry(31, 'لقمان', 'Luqman'),
  SurahNameEntry(32, 'السجدة', 'As-Sajdah'),
  SurahNameEntry(33, 'الأحزاب', 'Al-Ahzab'),
  SurahNameEntry(34, 'سبأ', 'Saba'),
  SurahNameEntry(35, 'فاطر', 'Fatir'),
  SurahNameEntry(36, 'يس', 'Ya-Sin'),
  SurahNameEntry(37, 'الصافات', 'As-Saffat'),
  SurahNameEntry(38, 'ص', 'Sad'),
  SurahNameEntry(39, 'الزمر', 'Az-Zumar'),
  SurahNameEntry(40, 'غافر', 'Ghafir'),
  SurahNameEntry(41, 'فصلت', 'Fussilat'),
  SurahNameEntry(42, 'الشورى', 'Ash-Shuraa'),
  SurahNameEntry(43, 'الزخرف', 'Az-Zukhruf'),
  SurahNameEntry(44, 'الدخان', 'Ad-Dukhan'),
  SurahNameEntry(45, 'الجاثية', 'Al-Jathiyah'),
  SurahNameEntry(46, 'الأحقاف', 'Al-Ahqaf'),
  SurahNameEntry(47, 'محمد', 'Muhammad'),
  SurahNameEntry(48, 'الفتح', 'Al-Fath'),
  SurahNameEntry(49, 'الحجرات', 'Al-Hujurat'),
  SurahNameEntry(50, 'ق', 'Qaf'),
  SurahNameEntry(51, 'الذاريات', 'Adh-Dhariyat'),
  SurahNameEntry(52, 'الطور', 'At-Tur'),
  SurahNameEntry(53, 'النجم', 'An-Najm'),
  SurahNameEntry(54, 'القمر', 'Al-Qamar'),
  SurahNameEntry(55, 'الرحمن', 'Ar-Rahman'),
  SurahNameEntry(56, 'الواقعة', "Al-Waqi'ah"),
  SurahNameEntry(57, 'الحديد', 'Al-Hadid'),
  SurahNameEntry(58, 'المجادلة', 'Al-Mujadilah'),
  SurahNameEntry(59, 'الحشر', 'Al-Hashr'),
  SurahNameEntry(60, 'الممتحنة', 'Al-Mumtahanah'),
  SurahNameEntry(61, 'الصف', 'As-Saff'),
  SurahNameEntry(62, 'الجمعة', "Al-Jumu'ah"),
  SurahNameEntry(63, 'المنافقون', 'Al-Munafiqun'),
  SurahNameEntry(64, 'التغابن', 'At-Taghabun'),
  SurahNameEntry(65, 'الطلاق', 'At-Talaq'),
  SurahNameEntry(66, 'التحريم', 'At-Tahrim'),
  SurahNameEntry(67, 'الملك', 'Al-Mulk'),
  SurahNameEntry(68, 'القلم', 'Al-Qalam'),
  SurahNameEntry(69, 'الحاقة', 'Al-Haqqah'),
  SurahNameEntry(70, 'المعارج', "Al-Ma'arij"),
  SurahNameEntry(71, 'نوح', 'Nuh'),
  SurahNameEntry(72, 'الجن', 'Al-Jinn'),
  SurahNameEntry(73, 'المزمل', 'Al-Muzzammil'),
  SurahNameEntry(74, 'المدثر', 'Al-Muddaththir'),
  SurahNameEntry(75, 'القيامة', 'Al-Qiyamah'),
  SurahNameEntry(76, 'الانسان', 'Al-Insan'),
  SurahNameEntry(77, 'المرسلات', 'Al-Mursalat'),
  SurahNameEntry(78, 'النبأ', 'An-Naba'),
  SurahNameEntry(79, 'النازعات', "An-Nazi'at"),
  SurahNameEntry(80, 'عبس', 'Abasa'),
  SurahNameEntry(81, 'التكوير', 'At-Takwir'),
  SurahNameEntry(82, 'الإنفطار', 'Al-Infitar'),
  SurahNameEntry(83, 'المطففين', 'Al-Mutaffifin'),
  SurahNameEntry(84, 'الإنشقاق', 'Al-Inshiqaq'),
  SurahNameEntry(85, 'البروج', 'Al-Buruj'),
  SurahNameEntry(86, 'الطارق', 'At-Tariq'),
  SurahNameEntry(87, 'الأعلى', "Al-A'la"),
  SurahNameEntry(88, 'الغاشية', 'Al-Ghashiyah'),
  SurahNameEntry(89, 'الفجر', 'Al-Fajr'),
  SurahNameEntry(90, 'البلد', 'Al-Balad'),
  SurahNameEntry(91, 'الشمس', 'Ash-Shams'),
  SurahNameEntry(92, 'الليل', 'Al-Layl'),
  SurahNameEntry(93, 'الضحى', 'Ad-Duhaa'),
  SurahNameEntry(94, 'الشرح', 'Ash-Sharh'),
  SurahNameEntry(95, 'التين', 'At-Tin'),
  SurahNameEntry(96, 'العلق', 'Al-Alaq'),
  SurahNameEntry(97, 'القدر', 'Al-Qadr'),
  SurahNameEntry(98, 'البينة', 'Al-Bayyinah'),
  SurahNameEntry(99, 'الزلزلة', 'Az-Zalzalah'),
  SurahNameEntry(100, 'العاديات', 'Al-Adiyat'),
  SurahNameEntry(101, 'القارعة', "Al-Qari'ah"),
  SurahNameEntry(102, 'التكاثر', 'At-Takathur'),
  SurahNameEntry(103, 'العصر', 'Al-Asr'),
  SurahNameEntry(104, 'الهمزة', 'Al-Humazah'),
  SurahNameEntry(105, 'الفيل', 'Al-Fil'),
  SurahNameEntry(106, 'قريش', 'Quraysh'),
  SurahNameEntry(107, 'الماعون', "Al-Ma'un"),
  SurahNameEntry(108, 'الكوثر', 'Al-Kawthar'),
  SurahNameEntry(109, 'الكافرون', 'Al-Kafirun'),
  SurahNameEntry(110, 'النصر', 'An-Nasr'),
  SurahNameEntry(111, 'المسد', 'Al-Masad'),
  SurahNameEntry(112, 'الإخلاص', 'Al-Ikhlas'),
  SurahNameEntry(113, 'الفلق', 'Al-Falaq'),
  SurahNameEntry(114, 'الناس', 'An-Nas'),
];

class MushafTranslationOption {
  final String identifier;
  final String displayName;
  const MushafTranslationOption(this.identifier, this.displayName);
}

const List<MushafTranslationOption> mushafAvailableTranslations = [
  MushafTranslationOption('en.sahih', 'English — Saheeh International'),
  MushafTranslationOption('ur.jalandhry', 'Urdu — Jalandhry'),
  MushafTranslationOption('id.indonesian', 'Indonesian — Kemenag'),
  MushafTranslationOption('fr.hamidullah', 'French — Hamidullah'),
];