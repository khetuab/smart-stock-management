import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quran_page_model.dart';
import '../../data/services/quran_services.dart';

/// Drives a continuous, book-style Quran reader: one surah's ayahs at a
/// time in a flowing scroll (not a fixed 604-page mushaf replica), with the
/// reading position (surah + topmost visible ayah) persisted so reopening
/// the screen resumes exactly where the user left off.
class QuranReaderController extends GetxController with WidgetsBindingObserver {
  static const int totalSurahs = 114;
  static const String _lastSurahKey = 'quran_last_surah';
  static const String _lastAyahIndexKey = 'quran_last_ayah_index';

  final QuranService _service = QuranService();

  // ---- SharedPreferences ----------------------------------------------
  // Cached instance + a single in-flight future so every caller awaits the
  // SAME future instead of racing separate getInstance() calls.
  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsFuture;
  Future<SharedPreferences> get _prefsInstance {
    if (_prefs != null) return Future.value(_prefs);
    return _prefsFuture ??= SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  // scrollable_positioned_list handles index-accurate scroll restoration
  // for us — no manual pixel/frame-timing math, no PageController races.
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  final RxInt currentSurah = 1.obs;
  // Consumed as `initialScrollIndex` the next time the ayah list is built
  // (the list widget is keyed by surah, so a new surah always gets a fresh
  // scroll state that honors this correctly).
  final RxInt initialAyahIndex = 0.obs;

  final RxList<QuranAyah> ayahs = <QuranAyah>[].obs;
  final RxList<QuranSurahMeta> surahList = <QuranSurahMeta>[].obs;

  final RxBool isBootstrapping = true.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // ---- Reading settings ----
  final RxDouble fontSize = 26.0.obs;
  final RxBool showTranslation = false.obs;
  final RxString translationEdition = availableTranslations.first.identifier.obs;
  final RxBool sepiaMode = false.obs;

  int _lastSavedAyahIndex = -1;
  int _lastSavedSurah = -1;
  Timer? _saveDebounce;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    itemPositionsListener.itemPositions.addListener(_onScrollPositionsChanged);
    _bootstrap();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    itemPositionsListener.itemPositions.removeListener(_onScrollPositionsChanged);
    _saveDebounce?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Safety net: flush the reading position as soon as the app is
    // backgrounded, in case it's killed before a debounced save would
    // otherwise have completed.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (itemPositionsListener.itemPositions.value.isNotEmpty) {
        _savePosition(currentSurah.value, _topVisibleIndex());
      }
    }
  }

  Future<void> _bootstrap() async {
    final prefs = await _prefsInstance;

    // Best-effort — the reader itself doesn't need this to function, only
    // the surah picker sheet does.
    unawaited(_loadSurahList());

    final args = Get.arguments;
    final requestedSurah = (args is Map && args['surah'] is int) ? args['surah'] as int : null;
    // Only an explicit forced navigation (e.g. tapping a bookmark or a
    // search result) is allowed to override where the user left off — a
    // plain `surah` argument alone must not silently discard the saved
    // reading position.
    final forceSurah = args is Map && args['forceSurah'] == true;
    final requestedAyahIndex = (args is Map && args['ayahIndex'] is int) ? args['ayahIndex'] as int : 0;

    final savedSurah = prefs.getInt(_lastSurahKey);
    final savedAyahIndex = prefs.getInt(_lastAyahIndexKey) ?? 0;

    int startSurah;
    int startAyahIndex;
    if (forceSurah && requestedSurah != null) {
      startSurah = requestedSurah;
      startAyahIndex = requestedAyahIndex;
    } else if (savedSurah != null) {
      startSurah = savedSurah;
      startAyahIndex = savedAyahIndex;
    } else if (requestedSurah != null) {
      startSurah = requestedSurah;
      startAyahIndex = requestedAyahIndex;
    } else {
      startSurah = 1;
      startAyahIndex = 0;
    }
    startSurah = startSurah.clamp(1, totalSurahs);

    isBootstrapping.value = false;
    await _loadSurah(startSurah, initialIndex: startAyahIndex);
  }

  Future<void> _loadSurahList() async {
    try {
      surahList.value = await _service.fetchSurahList();
    } catch (_) {
      // Non-fatal — the reader itself doesn't depend on this.
    }
  }

  Future<void> _loadSurah(int surahNumber, {int initialIndex = 0}) async {
    isLoading.value = true;
    errorMessage.value = '';
    _lastSavedAyahIndex = -1;
    _lastSavedSurah = -1;
    try {
      final data = await _service.fetchSurah(
        surahNumber,
        translationEdition: showTranslation.value ? translationEdition.value : null,
      );
      ayahs.value = data;
      currentSurah.value = surahNumber;
      initialAyahIndex.value = data.isEmpty ? 0 : initialIndex.clamp(0, data.length - 1);
      isLoading.value = false;
      await _savePosition(surahNumber, initialAyahIndex.value);
    } catch (_) {
      ayahs.clear();
      currentSurah.value = surahNumber;
      errorMessage.value = 'failedToLoadQuranPage'.tr;
      isLoading.value = false;
    }
  }

  /// Called from the surah picker, from next/previous, and from jump
  /// actions.
  Future<void> goToSurah(int surahNumber, {int ayahIndex = 0}) {
    return _loadSurah(surahNumber.clamp(1, totalSurahs), initialIndex: ayahIndex);
  }

  void retry() => _loadSurah(currentSurah.value, initialIndex: initialAyahIndex.value);

  void nextSurah() {
    if (currentSurah.value < totalSurahs) goToSurah(currentSurah.value + 1);
  }

  void previousSurah() {
    if (currentSurah.value > 1) goToSurah(currentSurah.value - 1);
  }

  void setShowTranslation(bool value) {
    showTranslation.value = value;
    _loadSurah(currentSurah.value, initialIndex: _topVisibleIndex());
  }

  void setTranslationEdition(String identifier) {
    translationEdition.value = identifier;
    if (showTranslation.value) {
      _loadSurah(currentSurah.value, initialIndex: _topVisibleIndex());
    }
  }

  void setFontSize(double value) => fontSize.value = value;
  void setSepiaMode(bool value) => sepiaMode.value = value;

  // ---- Position tracking ------------------------------------------------

  int _topVisibleIndex() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return 0;
    ItemPosition top = positions.first;
    for (final p in positions) {
      if (p.itemLeadingEdge < top.itemLeadingEdge) top = p;
    }
    return top.index;
  }

  void _onScrollPositionsChanged() {
    if (itemPositionsListener.itemPositions.value.isEmpty) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      _savePosition(currentSurah.value, _topVisibleIndex());
    });
  }

  Future<void> _savePosition(int surahNumber, int ayahIndex) async {
    if (ayahIndex == _lastSavedAyahIndex && surahNumber == _lastSavedSurah) return;
    _lastSavedAyahIndex = ayahIndex;
    _lastSavedSurah = surahNumber;
    final prefs = await _prefsInstance;
    await prefs.setInt(_lastSurahKey, surahNumber);
    await prefs.setInt(_lastAyahIndexKey, ayahIndex);
  }
}