import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/quran_mushaf_models.dart';
import '../../data/services/mushaf_data_service.dart';

/// Drives the page-by-page mushaf reader: 604 pages, navigated with a
/// [PageController], with the current page persisted so reopening the
/// screen resumes exactly where the user left off.
///
/// Independent of your existing surah-scroll controller — both can be
/// wired to their own routes and used side by side.
class QuranMushafController extends GetxController {
  static const int totalPages = MushafPage.totalPages;
  static const String _lastPageKey = 'quran_mushaf_last_page';

  final QuranMushafService _service = QuranMushafService();

  late final PageController pageController;

  final RxInt currentPage = 1.obs;
  final RxMap<int, MushafPage> pages = <int, MushafPage>{}.obs;
  final RxSet<int> loadingPages = <int>{}.obs;
  final RxSet<int> failedPages = <int>{}.obs;

  final RxBool isBootstrapping = true.obs;
  final RxDouble fontSize = 22.0.obs;
  final RxBool sepiaMode = false.obs;
  final RxBool showTranslation = false.obs;
  final RxString translationEdition = mushafAvailableTranslations.first.identifier.obs;

  SharedPreferences? _prefs;
  Timer? _saveDebounce;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _saveDebounce?.cancel();
    pageController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();

    int startPage = _prefs?.getInt(_lastPageKey) ?? 1;

    final args = Get.arguments;
    if (args is Map) {
      try {
        if (args['page'] is int) {
          startPage = args['page'] as int;
        } else if (args['surah'] is int) {
          startPage = await _service.fetchSurahStartPage(args['surah'] as int);
        } else if (args['juz'] is int) {
          startPage = await _service.fetchJuzStartPage(args['juz'] as int);
        }
      } catch (_) {
        // Keep whatever startPage already held (saved page, or page 1).
      }
    }

    startPage = startPage.clamp(1, totalPages);
    currentPage.value = startPage;
    pageController = PageController(initialPage: startPage - 1);
    isBootstrapping.value = false;

    await _loadPage(startPage);
    _prefetchAround(startPage);
  }

  Future<void> _loadPage(int pageNumber) async {
    if (pages.containsKey(pageNumber) || loadingPages.contains(pageNumber)) return;
    loadingPages.add(pageNumber);
    failedPages.remove(pageNumber);
    try {
      final page = await _service.fetchPage(
        pageNumber,
        translationEdition: showTranslation.value ? translationEdition.value : null,
      );
      pages[pageNumber] = page;
    } catch (_) {
      failedPages.add(pageNumber);
    } finally {
      loadingPages.remove(pageNumber);
    }
  }

  void _prefetchAround(int pageNumber) {
    for (final p in [pageNumber - 1, pageNumber + 1]) {
      if (p >= 1 && p <= totalPages) unawaited(_loadPage(p));
    }
  }

  void retryPage(int pageNumber) => _loadPage(pageNumber);

  /// Wire this to the [PageView]'s `onPageChanged`.
  void onPageChanged(int index) {
    final pageNumber = index + 1;
    currentPage.value = pageNumber;
    unawaited(_loadPage(pageNumber));
    _prefetchAround(pageNumber);
    _debouncedSave(pageNumber);
  }

  void jumpToPage(int pageNumber) {
    final target = pageNumber.clamp(1, totalPages);
    pageController.jumpToPage(target - 1);
    onPageChanged(target - 1);
  }

  Future<void> animateToPage(int pageNumber) async {
    final target = pageNumber.clamp(1, totalPages);
    await pageController.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  Future<void> goToSurah(int surahNumber) async {
    try {
      final page = await _service.fetchSurahStartPage(surahNumber);
      jumpToPage(page);
    } catch (_) {
      Get.snackbar('error'.tr, 'failedToLoadQuranPage'.tr);
    }
  }

  Future<void> goToJuz(int juzNumber) async {
    final page = await _service.fetchJuzStartPage(juzNumber);
    jumpToPage(page);
  }

  void nextPage() {
    if (currentPage.value < totalPages) jumpToPage(currentPage.value + 1);
  }

  void previousPage() {
    if (currentPage.value > 1) jumpToPage(currentPage.value - 1);
  }

  void setFontSize(double value) => fontSize.value = value;
  void setSepiaMode(bool value) => sepiaMode.value = value;

  void setShowTranslation(bool value) {
    showTranslation.value = value;
    pages.clear();
    unawaited(_loadPage(currentPage.value));
    _prefetchAround(currentPage.value);
  }

  void setTranslationEdition(String identifier) {
    translationEdition.value = identifier;
    if (showTranslation.value) setShowTranslation(true);
  }

  void _debouncedSave(int pageNumber) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () async {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt(_lastPageKey, pageNumber);
    });
  }
}