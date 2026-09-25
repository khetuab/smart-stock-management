import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_mushaf_models.dart';

/// Fetches mushaf pages from the free, keyless Al-Quran Cloud API
/// (https://alquran.cloud/api) and lays them out into 15-line pages.
///
/// This is the ONLY file that talks to the network for this feature — if
/// your app already standardizes on `dio` (or another HTTP client), the
/// swap is contained to the four `http.get(...)` calls below.
class QuranMushafService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _arabicEdition = 'quran-uthmani';

  SharedPreferences? _prefs;
  final Map<int, MushafPage> _memoryCache = {};
  final Map<int, int> _surahStartPageCache = {};
  final Map<int, int> _juzStartPageCache = {};

  Future<SharedPreferences> get _prefsInstance async => _prefs ??= await SharedPreferences.getInstance();

  /// Fetches (and lays out) page [pageNumber] (1-604). Results are cached
  /// both in memory and on disk, so re-opening a page you've already
  /// visited never re-hits the network.
  Future<MushafPage> fetchPage(int pageNumber, {String? translationEdition}) async {
    final cached = _memoryCache[pageNumber];
    if (cached != null && (translationEdition == null || cached.ayahs.any((a) => a.translation != null))) {
      return cached;
    }

    final prefs = await _prefsInstance;
    final cacheKey = 'quran_mushaf_page_$pageNumber';

    List<MushafAyah> ayahs;
    final cachedRaw = prefs.getString(cacheKey);
    if (cachedRaw != null) {
      ayahs = _parseAyahs(jsonDecode(cachedRaw) as Map<String, dynamic>);
    } else {
      final uri = Uri.parse('$_baseUrl/page/$pageNumber/$_arabicEdition');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw QuranMushafException('Failed to load page $pageNumber (HTTP ${response.statusCode})');
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      ayahs = _parseAyahs(decoded);
      unawaited(prefs.setString(cacheKey, jsonEncode(decoded)));
    }

    if (translationEdition != null && translationEdition.isNotEmpty) {
      try {
        final translations = await _fetchTranslationWords(pageNumber, translationEdition);
        ayahs = ayahs.map((a) => a.copyWithTranslation(translations[a.globalAyahNumber])).toList();
      } catch (_) {
        // Non-fatal: show the Arabic text even if the translation call fails.
      }
    }

    final juzNumber = ayahs.isNotEmpty ? ayahs.first.juz : 1;
    final page = MushafPage(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      ayahs: ayahs,
      lines: layOutPageLines(ayahs),
    );
    _memoryCache[pageNumber] = page;
    return page;
  }

  Future<Map<int, String>> _fetchTranslationWords(int pageNumber, String edition) async {
    final uri = Uri.parse('$_baseUrl/page/$pageNumber/$edition');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return {};
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final ayahsJson = data['ayahs'] as List<dynamic>? ?? [];
    return {for (final a in ayahsJson) (a['number'] as int): (a['text'] as String? ?? '')};
  }

  List<MushafAyah> _parseAyahs(Map<String, dynamic> decoded) {
    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final ayahsJson = data['ayahs'] as List<dynamic>? ?? [];
    return ayahsJson.map((a) => MushafAyah.fromAlQuranCloudJson(a as Map<String, dynamic>)).toList();
  }

  /// The page a surah starts on, per this same edition/pagination (fetched
  /// once per surah, then cached for the rest of the app's lifetime).
  Future<int> fetchSurahStartPage(int surahNumber) async {
    final cached = _surahStartPageCache[surahNumber];
    if (cached != null) return cached;
    final uri = Uri.parse('$_baseUrl/surah/$surahNumber/$_arabicEdition');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw QuranMushafException('Failed to resolve surah $surahNumber');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>? ?? {};
    final ayahs = data['ayahs'] as List<dynamic>? ?? [];
    if (ayahs.isEmpty) throw QuranMushafException('Surah $surahNumber has no ayahs');
    final page = ayahs.first['page'] as int? ?? 1;
    _surahStartPageCache[surahNumber] = page;
    return page;
  }

  /// The page a juz starts on. Falls back to the well-known standard
  /// 604-page mapping ([standardJuzStartPages]) if the network call fails.
  Future<int> fetchJuzStartPage(int juzNumber) async {
    final cached = _juzStartPageCache[juzNumber];
    if (cached != null) return cached;
    try {
      final uri = Uri.parse('$_baseUrl/juz/$juzNumber/$_arabicEdition?offset=0&limit=1');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw QuranMushafException('juz lookup failed');
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>? ?? {};
      final ayahs = data['ayahs'] as List<dynamic>? ?? [];
      final page = ayahs.isNotEmpty
          ? (ayahs.first['page'] as int? ?? standardJuzStartPages[juzNumber - 1])
          : standardJuzStartPages[juzNumber - 1];
      _juzStartPageCache[juzNumber] = page;
      return page;
    } catch (_) {
      return standardJuzStartPages[juzNumber.clamp(1, 30) - 1];
    }
  }

  /// Wipes the on-disk page cache (in-memory cache clears on app restart
  /// anyway). Useful if you ever change `_arabicEdition`.
  Future<void> clearDiskCache() async {
    final prefs = await _prefsInstance;
    final keys = prefs.getKeys().where((k) => k.startsWith('quran_mushaf_page_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

class QuranMushafException implements Exception {
  final String message;
  QuranMushafException(this.message);
  @override
  String toString() => message;
}