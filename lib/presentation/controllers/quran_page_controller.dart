import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
///
///  • Three simultaneous translations (English / Amharic / Arabic tafsir)
///    toggled per language — fetched together in one API call.
///  • Ayah-by-ayah audio recitation (audioplayers) with a highlighted
///    playing ayah and automatic advance + scroll.
///  • Robust audio: bitrate fallback, timeout, cancellation of stale loads
///    and throttled error messages (no more endless error loops).
class QuranReaderController extends GetxController with WidgetsBindingObserver {
  static const int totalSurahs = 114;
  static const String _lastSurahKey = 'quran_last_surah';
  static const String _lastAyahIndexKey = 'quran_last_ayah_index';
  static const String _translationsKey = 'quran_active_translations';
  static const String _reciterKey = 'quran_reciter';
  static const String _autoNextKey = 'quran_auto_next';

  // ---- Audio CDN config ------------------------------------------------
  static const String _audioCdn = 'https://cdn.islamic.network/quran/audio';

  /// Not every reciter is hosted at every bitrate, so we try these in order.
  static const List<int> _bitrates = [128, 192, 64, 48, 32];

  static const Duration _audioLoadTimeout = Duration(seconds: 12);
  static const Duration _errorSnackbarCooldown = Duration(seconds: 6);

  final QuranService _service = QuranService();

  // ---- SharedPreferences ----------------------------------------------
  SharedPreferences? _prefs;
  Future<SharedPreferences>? _prefsFuture;
  Future<SharedPreferences> get _prefsInstance {
    if (_prefs != null) return Future.value(_prefs);
    return _prefsFuture ??= SharedPreferences.getInstance().then((p) => _prefs = p);
  }

  // scrollable_positioned_list handles index-accurate scroll restoration
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  final RxInt currentSurah = 1.obs;
  final RxInt initialAyahIndex = 0.obs;

  final RxList<QuranAyah> ayahs = <QuranAyah>[].obs;
  final RxList<QuranSurahMeta> surahList = <QuranSurahMeta>[].obs;

  final RxBool isBootstrapping = true.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  // ---- Reading settings ----
  final RxDouble fontSize = 26.0.obs;
  final RxBool sepiaMode = false.obs;

  /// Which translation editions are currently shown (order = display order).
  final RxList<String> activeTranslations = <String>['en.sahih', 'am.sadiq'].obs;

  // ---- Audio recitation ----
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxBool isAudioPlaying = false.obs;
  final RxBool isAudioLoading = false.obs;

  /// Index (in [ayahs]) of the ayah currently being recited; -1 = none.
  final RxInt playingAyahIndex = (-1).obs;

  final RxString reciter = 'ar.alafasy'.obs;
  final RxBool autoPlayNext = true.obs;

  StreamSubscription? _completeSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _logSub;

  /// Incremented on every new play request / stop. A load that finishes with
  /// an old token is stale and must not touch state or show errors.
  int _playToken = 0;

  /// Remembers which bitrate worked for each reciter.
  final Map<String, int> _workingBitrate = {};

  DateTime? _lastErrorShownAt;

  int _lastSavedAyahIndex = -1;
  int _lastSavedSurah = -1;
  Timer? _saveDebounce;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    itemPositionsListener.itemPositions.addListener(_onScrollPositionsChanged);
    _bootstrap();
    _bindAudio();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    itemPositionsListener.itemPositions.removeListener(_onScrollPositionsChanged);
    _saveDebounce?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _logSub?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (itemPositionsListener.itemPositions.value.isNotEmpty) {
        _savePosition(currentSurah.value, _topVisibleIndex());
      }
    }
  }

  Future<void> _bootstrap() async {
    final prefs = await _prefsInstance;

    unawaited(_loadSurahList());

    // Restore reading preferences
    final savedTranslations = prefs.getStringList(_translationsKey);
    if (savedTranslations != null && savedTranslations.isNotEmpty) {
      activeTranslations.assignAll(
        savedTranslations.where((t) => availableTranslations.any((a) => a.identifier == t)),
      );
    }
    final savedReciter = prefs.getString(_reciterKey);
    if (savedReciter != null && savedReciter.isNotEmpty) reciter.value = savedReciter;
    autoPlayNext.value = prefs.getBool(_autoNextKey) ?? true;
    final savedFont = prefs.getDouble('quran_font_size');
    if (savedFont != null) fontSize.value = savedFont;
    sepiaMode.value = prefs.getBool('quran_sepia') ?? false;

    final args = Get.arguments;
    final requestedSurah = (args is Map && args['surah'] is int) ? args['surah'] as int : null;
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

    // Switching surah stops any ongoing recitation cleanly.
    stopRecitation();

    try {
      final data = await _service.fetchSurah(
        surahNumber,
        editions: activeTranslations.isEmpty ? null : activeTranslations.toList(),
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

  /// Called from the surah picker, from next/previous, and from jump actions.
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

  // ───────────────────────── TRANSLATION TOGGLES ─────────────────────────

  void toggleTranslation(String identifier) {
    if (activeTranslations.contains(identifier)) {
      activeTranslations.remove(identifier);
    } else {
      activeTranslations.add(identifier);
    }
    _prefsInstance.then((p) => p.setStringList(_translationsKey, activeTranslations.toList()));
    // Reload only when something changed meaningfully.
    _loadSurah(currentSurah.value, initialIndex: _topVisibleIndex());
  }

  void setFontSize(double value) {
    fontSize.value = value;
    _prefsInstance.then((p) => p.setDouble('quran_font_size', value));
  }

  void setSepiaMode(bool value) {
    sepiaMode.value = value;
    _prefsInstance.then((p) => p.setBool('quran_sepia', value));
  }

  void setReciter(String identifier) {
    if (reciter.value == identifier) return;
    reciter.value = identifier;
    _prefsInstance.then((p) => p.setString(_reciterKey, identifier));

    // If something is selected/playing, restart that ayah with the new reciter.
    final idx = playingAyahIndex.value;
    if (idx != -1) {
      stopRecitation();
      playAyah(idx);
    }
  }

  void setAutoNext(bool value) {
    autoPlayNext.value = value;
    _prefsInstance.then((p) => p.setBool(_autoNextKey, value));
  }

  // ─────────────────────────── AUDIO RECITATION ───────────────────────────

  void _bindAudio() {
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      // Ignore stray completion events after a stop / failure.
      if (playingAyahIndex.value == -1) return;

      // Advance to the next ayah automatically when enabled.
      if (autoPlayNext.value) {
        final next = playingAyahIndex.value + 1;
        if (next < ayahs.length) {
          playAyah(next);
        } else {
          stopRecitation();
        }
      } else {
        stopRecitation();
      }
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isAudioPlaying.value = true;
        isAudioLoading.value = false;
      } else if (state == PlayerState.paused) {
        isAudioPlaying.value = false;
        isAudioLoading.value = false;
      } else if (state == PlayerState.stopped) {
        isAudioPlaying.value = false;
      }
    });

    // Platform errors are also reported through the log stream; we handle
    // them in playAyah(), so here we only keep them out of the console noise.
    _logSub = _audioPlayer.onLog.listen(
          (msg) => debugPrint('AudioPlayer log: $msg'),
      onError: (Object e) => debugPrint('AudioPlayer log error: $e'),
    );
  }

  String _audioUrl(int ayahGlobalNumber, String reciterId, int bitrate) =>
      '$_audioCdn/$bitrate/$reciterId/$ayahGlobalNumber.mp3';

  /// Bitrates to try for [reciterId]: the known-good one first, then the rest.
  List<int> _bitrateOrder(String reciterId) {
    final known = _workingBitrate[reciterId];
    if (known == null) return _bitrates;
    return [known, ..._bitrates.where((b) => b != known)];
  }

  /// Tries every bitrate until one loads. Returns true on success.
  /// Gives up silently (returns false) if a newer request supersedes [token].
  Future<bool> _loadAndPlay(int ayahGlobalNumber, String reciterId, int token) async {
    for (final bitrate in _bitrateOrder(reciterId)) {
      if (token != _playToken) return false; // superseded
      final url = _audioUrl(ayahGlobalNumber, reciterId, bitrate);
      try {
        await _audioPlayer.play(UrlSource(url)).timeout(_audioLoadTimeout);
        if (token != _playToken) return false;
        _workingBitrate[reciterId] = bitrate;
        return true;
      } catch (e) {
        debugPrint('Audio failed ($bitrate kbps) $url -> $e');
        // try the next bitrate
      }
    }
    return false;
  }

  /// Play (or pause) the ayah at [index].
  Future<void> playAyah(int index) async {
    if (index < 0 || index >= ayahs.length) return;

    try {
      // Tapping the currently playing ayah pauses it.
      if (playingAyahIndex.value == index && isAudioPlaying.value) {
        await _audioPlayer.pause();
        isAudioPlaying.value = false;
        return;
      }
      // Tapping the paused current ayah resumes it.
      if (playingAyahIndex.value == index && !isAudioPlaying.value && !isAudioLoading.value) {
        await _audioPlayer.resume();
        isAudioPlaying.value = true;
        return;
      }
    } catch (e) {
      debugPrint('Pause/resume failed: $e');
      // fall through and reload the ayah from scratch
    }

    final token = ++_playToken;
    isAudioLoading.value = true;
    isAudioPlaying.value = false;
    playingAyahIndex.value = index;

    final ok = await _loadAndPlay(ayahs[index].number, reciter.value, token);

    if (token != _playToken) return; // a newer request owns the state now

    if (ok) {
      _scrollToPlaying(index);
    } else {
      _handlePlaybackFailure();
    }
  }

  /// Resets audio state after a failure and shows ONE throttled message.
  /// Never auto-advances, so a bad file can't cause an error loop.
  void _handlePlaybackFailure() {
    _playToken++; // cancel anything still pending
    isAudioLoading.value = false;
    isAudioPlaying.value = false;
    playingAyahIndex.value = -1;
    unawaited(_audioPlayer.stop().catchError((_) {}));

    final now = DateTime.now();
    final last = _lastErrorShownAt;
    if (last != null && now.difference(last) < _errorSnackbarCooldown) return;
    _lastErrorShownAt = now;

    Get.snackbar(
      'Error',
      'audioFailed'.tr,
      snackPosition: SnackPosition.BOTTOM,
      colorText: Get.theme.colorScheme.error,
    );
  }

  void _scrollToPlaying(int index) {
    if (itemScrollController.isAttached) {
      itemScrollController.scrollTo(
        index: index,
        alignment: 0.15,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> pauseRecitation() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Pause failed: $e');
    }
    isAudioPlaying.value = false;
  }

  Future<void> stopRecitation() async {
    _playToken++; // cancels any in-flight load
    isAudioPlaying.value = false;
    isAudioLoading.value = false;
    playingAyahIndex.value = -1;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Play the whole surah from the first ayah (or resume).
  Future<void> playSurah() async {
    if (ayahs.isEmpty) return;
    if (playingAyahIndex.value == -1) {
      await playAyah(0);
    } else {
      try {
        await _audioPlayer.resume();
        isAudioPlaying.value = true;
      } catch (e) {
        debugPrint('Resume failed: $e');
        await playAyah(playingAyahIndex.value); // reload current ayah
      }
    }
  }

  // ─────────────────────────── POSITION TRACKING ───────────────────────────

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