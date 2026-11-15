import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_page_model.dart';

/// Fetches the standard Uthmani Quran text and up to three translations
/// (English, Amharic, Arabic tafsir) from the AlQuran Cloud public API
/// (https://alquran.cloud/api), one surah at a time, for a continuous
/// book-style reading experience.
///
/// We deliberately fetch from a verified source rather than storing Quran
/// text locally in the app — accuracy matters too much here to risk a
/// transcription error.
class QuranService {
  static const String _base = 'https://api.alquran.cloud/v1';
  static const Duration _timeout = Duration(seconds: 12);

  /// Edition identifiers (verified against the live API):
  ///  en.sahih  — Saheeh International (English)
  ///  am.sadiq  — ሳዲቅ & ሳኒ ሐቢብ (Amharic)
  ///  ar.muyassar — King Fahad Complex tafsir (Arabic)
  static const String arabicEdition = 'quran-uthmani';
  static const List<String> translationEditions = ['en.sahih', 'am.sadiq', 'ar.muyassar'];

  /// Metadata for all 114 surahs (number, Arabic/English names, ayah
  /// count) — used to populate the surah picker.
  Future<List<QuranSurahMeta>> fetchSurahList() async {
    final res = await http.get(Uri.parse('$_base/surah')).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load surah list (${res.statusCode})');
    }
    final data = jsonDecode(res.body)['data'] as List;
    return data
        .map((s) => QuranSurahMeta.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// All ayahs of surah [surahNumber] (1-114). Translations requested via
  /// [editions] are merged alongside the Arabic text in ONE request using
  /// the multi-edition endpoint — the whole surah arrives in a single call.
  Future<List<QuranAyah>> fetchSurah(int surahNumber, {List<String>? editions}) async {
    final wanted = (editions == null || editions.isEmpty) ? const <String>[] : editions;
    final url = wanted.isEmpty
        ? '$_base/surah/$surahNumber/$arabicEdition'
        : '$_base/surah/$surahNumber/editions/$arabicEdition,${wanted.join(',')}';

    final res = await http.get(Uri.parse(url)).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load surah $surahNumber (${res.statusCode})');
    }

    final body = jsonDecode(res.body)['data'];

    // Multi-edition endpoint returns a LIST; single-edition returns an OBJECT.
    final List editionList =
        body is List ? body : <dynamic>[body];

    if (editionList.isEmpty) {
      throw Exception('Empty payload for surah $surahNumber');
    }

    final arabicData = editionList.first as Map<String, dynamic>;
    final ayahsJson = arabicData['ayahs'] as List;
    final surahName = arabicData['name'] as String;
    final surahEnglishName = arabicData['englishName'] as String;

    // translationEdition -> (numberInSurah -> text)
    final Map<String, Map<int, String>> translationsByEdition = {};
    for (int e = 1; e < editionList.length; e++) {
      try {
        final ed = editionList[e] as Map<String, dynamic>;
        final identifier = ed['edition']['identifier'] as String;
        final map = <int, String>{};
        for (final a in (ed['ayahs'] as List)) {
          map[a['numberInSurah'] as int] = a['text'] as String;
        }
        translationsByEdition[identifier] = map;
      } catch (_) {
        // Malformed edition payload — skip it, Arabic still renders.
      }
    }

    return ayahsJson.map((a) {
      final json = a as Map<String, dynamic>;
      final translations = <String, String>{};
      translationsByEdition.forEach((edition, map) {
        final t = map[json['numberInSurah'] as int];
        if (t != null) translations[edition] = t;
      });

      return QuranAyah(
        number: json['number'] as int,
        text: json['text'] as String,
        numberInSurah: json['numberInSurah'] as int,
        juz: json['juz'] as int,
        page: json['page'] as int,
        surahNumber: surahNumber,
        surahName: surahName,
        surahEnglishName: surahEnglishName,
        translations: translations,
      );
    }).toList();
  }

  /// Streamable audio URL for one ayah (global ayah number 1–6236).
  /// [bitrate] accepts 32/40/48/64/128/192 as offered by the CDN.
  static String ayahAudioUrl(int globalAyahNumber,
      {String reciter = 'ar.alafasy', int bitrate = 128}) {
    return 'https://cdn.islamic.network/quran/audio/$bitrate/$reciter/$globalAyahNumber.mp3';
  }
}
