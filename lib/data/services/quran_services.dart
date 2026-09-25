import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_page_model.dart';

/// Fetches the standard Uthmani Quran text (and optional translation) from
/// the AlQuran Cloud public API (https://alquran.cloud/api), one surah at a
/// time, for a continuous book-style reading experience rather than a fixed
/// 604-page mushaf-image replica.
///
/// We deliberately fetch this from a verified source rather than storing
/// Quran text locally in the app — accuracy matters too much here to risk a
/// transcription error.
class QuranService {
  static const String _base = 'https://api.alquran.cloud/v1';
  static const Duration _timeout = Duration(seconds: 8);

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

  /// All ayahs of surah [surahNumber] (1-114), with an optional translation
  /// merged in alongside the Arabic text.
  Future<List<QuranAyah>> fetchSurah(int surahNumber, {String? translationEdition}) async {
    // Fire the Arabic text and translation requests together instead of one
    // after another — halves latency per surah when a translation is on.
    final arabicFuture = http
        .get(Uri.parse('$_base/surah/$surahNumber/quran-uthmani'))
        .timeout(_timeout);

    final translationFuture = translationEdition == null
        ? Future<http.Response?>.value(null)
        : _fetchTranslationSafely(surahNumber, translationEdition);

    final arabicRes = await arabicFuture;
    if (arabicRes.statusCode != 200) {
      throw Exception('Failed to load surah $surahNumber (${arabicRes.statusCode})');
    }
    final arabicData = jsonDecode(arabicRes.body)['data'] as Map<String, dynamic>;
    final ayahsJson = arabicData['ayahs'] as List;
    final surahName = arabicData['name'] as String;
    final surahEnglishName = arabicData['englishName'] as String;

    final Map<int, String> translations = {};
    final tRes = await translationFuture;
    if (tRes != null && tRes.statusCode == 200) {
      try {
        final tData = jsonDecode(tRes.body)['data'] as Map<String, dynamic>;
        for (final a in (tData['ayahs'] as List)) {
          translations[a['numberInSurah'] as int] = a['text'] as String;
        }
      } catch (_) {
        // Malformed translation payload — Arabic text still renders.
      }
    }

    return ayahsJson.map((a) {
      final json = a as Map<String, dynamic>;
      final ayah = QuranAyah(
        number: json['number'] as int,
        text: json['text'] as String,
        numberInSurah: json['numberInSurah'] as int,
        juz: json['juz'] as int,
        page: json['page'] as int,
        surahNumber: surahNumber,
        surahName: surahName,
        surahEnglishName: surahEnglishName,
      );
      return ayah.copyWithTranslation(translations[ayah.numberInSurah]);
    }).toList();
  }

  /// Translation is best-effort — any failure (timeout, non-200, network
  /// error) returns null rather than throwing, so it never blocks the
  /// Arabic text from displaying.
  Future<http.Response?> _fetchTranslationSafely(int surahNumber, String edition) async {
    try {
      return await http.get(Uri.parse('$_base/surah/$surahNumber/$edition')).timeout(_timeout);
    } catch (_) {
      return null;
    }
  }
}