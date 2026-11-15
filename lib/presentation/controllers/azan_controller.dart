// lib/presentation/controllers/azan_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../../data/services/shared_preferences_service.dart';
import 'islamic_controller.dart';

/// `key` is the file name (without extension) in
/// android/app/src/main/res/raw/  — e.g. azan_makkah.mp3
class AzanVoice {
  final String key;
  final String label;
  final String subtitle;
  const AzanVoice(this.key, this.label, this.subtitle);
}

const kAzanVoices = <AzanVoice>[
  AzanVoice('azan_alaqsa', 'Al-Aqsa', 'Jerusalem'),
  AzanVoice('islam_azan', 'Islam', 'Islam Soubhi'),
  AzanVoice('azan_makkah', 'Makkah', 'Masjid al-Haram'),
  AzanVoice('azan_madinah', 'Madinah', 'Masjid an-Nabawi'),
  AzanVoice('azan_short', 'Short call', 'A brief takbir · about 20 s'),
];

/// Prayers that get an azan (Sunrise is not a prayer, so it has none).
const kAzanPrayers = <String>['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

const kAzanArabic = <String, String>{
  'Fajr': 'الفجر',
  'Dhuhr': 'الظهر',
  'Asr': 'العصر',
  'Maghrib': 'المغرب',
  'Isha': 'العشاء',
};

/// Translate [key], falling back to [fallback] when no translation exists.
String azanTr(String key, String fallback) {
  final v = key.tr;
  return v == key ? fallback : v;
}

class AzanController extends GetxController with WidgetsBindingObserver {
  static AzanController get to {
    if (Get.isRegistered<AzanController>()) return Get.find<AzanController>();
    return Get.put(AzanController(), permanent: true);
  }

  static const _ch = MethodChannel('app.azan/native');
  static const _horizonDays = 14;

  final SharedPreferencesService _prefs = SharedPreferencesService();

  // ── Settings (persisted) ──
  final master = false.obs;
  final enabled = <String, bool>{for (final p in kAzanPrayers) p: true}.obs;
  final sound = kAzanVoices.first.key.obs;
  final fajrSound = kAzanVoices.first.key.obs;

  // ── Runtime state ──
  final previewing = ''.obs;
  final notificationsOk = true.obs;
  final exactAlarmOk = true.obs;

  double? _lat;
  double? _lng;
  bool _running = false;
  bool _again = false;

  bool get _android => Platform.isAndroid;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    master.value = (_prefs.getInt('azanMaster') ?? 0) == 1;

    final csv = _prefs.getString('azanEnabled');
    if (csv != null) {
      final on = csv.split(',').where((s) => s.isNotEmpty).toSet();
      for (final p in kAzanPrayers) {
        enabled[p] = on.contains(p);
      }
    }

    sound.value = _prefs.getString('azanSound') ?? kAzanVoices.first.key;
    fajrSound.value = _prefs.getString('azanFajrSound') ?? sound.value;
    _lat = double.tryParse(_prefs.getString('azanLat') ?? '');
    _lng = double.tryParse(_prefs.getString('azanLng') ?? '');

    if (_android) {
      _ch.setMethodCallHandler((call) async {
        if (call.method == 'previewDone') previewing.value = '';
      });
    }

    refreshPermissions();
    reschedule(); // extends the 14-day horizon on every app start
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _safe(() => _ch.invokeMethod('stopPreview'));
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPermissions();
      reschedule();
    } else if (state == AppLifecycleState.paused) {
      stopPreview();
    }
  }

  String voiceLabel(String key) =>
      kAzanVoices.firstWhere((v) => v.key == key, orElse: () => kAzanVoices.first).label;

  // ───────────────────────── permissions ─────────────────────────

  Future<void> refreshPermissions() async {
    if (!_android) return;
    notificationsOk.value = await Permission.notification.isGranted;
    exactAlarmOk.value = await _canExact();
  }

  Future<bool> _canExact() async {
    try {
      return await _ch.invokeMethod<bool>('canScheduleExact') ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestPermissions() async {
    if (!_android) return;
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (!await _canExact()) {
      await _safe(() => _ch.invokeMethod('openExactAlarmSettings'));
    }
    await refreshPermissions();
  }

  // ───────────────────────── settings ─────────────────────────

  Future<void> setMaster(bool v) async {
    HapticFeedback.selectionClick();
    if (v) await requestPermissions();
    master.value = v;
    await _prefs.setInt('azanMaster', v ? 1 : 0);
    await reschedule();
  }

  Future<void> togglePrayer(String prayer) async {
    HapticFeedback.selectionClick();
    enabled[prayer] = !(enabled[prayer] ?? true);
    await _prefs.setString(
      'azanEnabled',
      enabled.entries.where((e) => e.value).map((e) => e.key).join(','),
    );
    await reschedule();
  }

  Future<void> setSound(String key) async {
    sound.value = key;
    await _prefs.setString('azanSound', key);
    await reschedule();
  }

  Future<void> setFajrSound(String key) async {
    fajrSound.value = key;
    await _prefs.setString('azanFajrSound', key);
    await reschedule();
  }

  // ───────────────────────── preview / test ─────────────────────────

  Future<void> preview(String key) async {
    if (!_android) return;
    if (previewing.value == key) {
      await stopPreview();
      return;
    }
    previewing.value = key;
    await _safe(() => _ch.invokeMethod('preview', {'sound': key}));
  }

  Future<void> stopPreview() async {
    if (!_android) return;
    previewing.value = '';
    await _safe(() => _ch.invokeMethod('stopPreview'));
  }

  /// Plays the real azan notification right now so the user can try
  /// pulling down the notification panel or pressing a side key.
  Future<void> testAzan() async {
    if (!_android) return;
    await stopPreview();
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    await _safe(() => _ch.invokeMethod('test', {
      'sound': sound.value,
      'title': azanTr('azanTest', 'Azan test'),
      'body': azanTr('azanTestBody', 'Open the notification panel or press a side key to silence it.'),
    }));
  }

  // ───────────────────────── scheduling ─────────────────────────

  /// Call with coordinates after a successful GPS fetch; call with no
  /// arguments to re-apply the current settings.
  Future<void> reschedule({double? lat, double? lng}) async {
    if (lat != null && lng != null) {
      _lat = lat;
      _lng = lng;
      await _prefs.setString('azanLat', lat.toString());
      await _prefs.setString('azanLng', lng.toString());
    }
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _doSchedule();
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<void> _doSchedule() async {
    if (!_android) return;

    final wantAny = master.value && enabled.values.any((v) => v);
    if (!wantAny) {
      await _safe(() => _ch.invokeMethod('cancelAll'));
      return;
    }
    if (_lat == null || _lng == null) return;

    final days = await _loadTimings();
    if (days.isEmpty) return; // offline: keep the schedule we already have

    final now = DateTime.now();
    final items = <Map<String, dynamic>>[];

    for (var d = 0; d < _horizonDays; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      final timings = days[_dayKey(day)];
      if (timings == null) continue;

      for (var i = 0; i < kAzanPrayers.length; i++) {
        final name = kAzanPrayers[i];
        if (enabled[name] != true) continue;
        final at = _parse(day, timings[name]?.toString());
        if (at == null || !at.isAfter(now.add(const Duration(seconds: 3)))) continue;

        items.add({
          'id': 1000 + d * 10 + i,
          'at': at.millisecondsSinceEpoch,
          'title': '$name · ${kAzanArabic[name]}',
          'body': azanTr('azanNotifBody', 'It is time for prayer'),
          'sound': name == 'Fajr' ? fajrSound.value : sound.value,
        });
      }
    }

    await _safe(() => _ch.invokeMethod('schedule', {'items': items}));
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  DateTime? _parse(DateTime day, String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (m == null) return null;
    return DateTime(day.year, day.month, day.day, int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  /// Aladhan monthly calendar for every month the horizon touches.
  Future<Map<String, Map<String, dynamic>>> _loadTimings() async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: _horizonDays));
    final months = <DateTime>{DateTime(now.year, now.month), DateTime(end.year, end.month)};

    final islamic = IslamicController.to;
    final out = <String, Map<String, dynamic>>{};

    for (final m in months) {
      try {
        final url = 'https://api.aladhan.com/v1/calendar'
            '?latitude=$_lat&longitude=$_lng'
            '&method=${islamic.calculationMethod.value}'
            '&school=${islamic.asrSchool.value}'
            '&month=${m.month}&year=${m.year}';
        final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (r.statusCode != 200) continue;

        for (final e in (jsonDecode(r.body)['data'] as List)) {
          final g = e['date']['gregorian']['date'].toString().split('-'); // dd-MM-yyyy
          out['${int.parse(g[2])}-${int.parse(g[1])}-${int.parse(g[0])}'] =
          Map<String, dynamic>.from(e['timings'] as Map);
        }
      } catch (_) {
        // ignore this month; we schedule what we have
      }
    }
    return out;
  }

  Future<void> _safe(Future<dynamic> Function() run) async {
    try {
      await run();
    } catch (_) {
      // MissingPluginException on non-Android / platform errors: ignore
    }
  }
}