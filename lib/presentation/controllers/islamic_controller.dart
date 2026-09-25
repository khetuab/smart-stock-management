// lib/presentation/controllers/islamic_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/shared_preferences_service.dart';
import 'package:geocoding/geocoding.dart' as geo;

class IslamicController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();

  // ====== MAKE IT A SINGLETON ======
  static IslamicController get to {
    if (Get.isRegistered<IslamicController>()) {
      return Get.find<IslamicController>();
    }
    return Get.put(IslamicController(), permanent: true);
  }

  // Prayer Times
  var prayerTimes = <String, String>{}.obs;
  var isLoading = false.obs;
  var currentLocation = ''.obs;
  var errorMessage = ''.obs;

  // Tasbih
  var tasbihCount = 0.obs;
  var tasbihTotal = 33.obs;
  var tasbihType = 'تسبيح'.obs;

  // Qibla
  var compassHeading = 0.0.obs;
  var qiblaBearing = 0.0.obs;
  var isCompassAvailable = false.obs;
  StreamSubscription<CompassEvent>? _compassSubscription;

  // Hijri Date
  var hijriDate = ''.obs;
  var gregorianDate = ''.obs;

  // Quran
  var quranData = <Map<String, dynamic>>[].obs;
  var selectedSurah = 1.obs;
  var selectedAyah = 0.obs;
  var isQuranLoading = false.obs;

  // Tasbih options
  final List<String> tasbihWords = ["تسبيح", "تحميد","تكبير","صلاة على النبي"];

  bool _isConnectionError(dynamic e) {
    if (e is SocketException) return true;
    if (e is TimeoutException) return true;
    if (e is HttpException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection timed out') ||
        msg.contains('connection refused') ||
        msg.contains('clientexception');
  }

  String _friendlyError(dynamic e, {String fallback = 'Something went wrong. Please try again.'}) {
    return _isConnectionError(e) ? 'Connection error, try again' : fallback;
  }

  @override
  void onInit() {
    super.onInit();
    calculationMethod.value = _prefs.getInt('prayerCalcMethod') ?? 3;
    asrSchool.value = _prefs.getInt('prayerAsrSchool') ?? 0;
    _loadHijriDate();
    fetchPrayerTimes();
    startQiblaCompass();
  }

  @override
  void onClose() {
    _compassSubscription?.cancel();
    super.onClose();
  }

  // islamic_controller.dart

// Settings (persisted)
  var calculationMethod = 3.obs; // Default: Muslim World League
  var asrSchool = 0.obs;         // 0 = Shafi/Maliki/Hanbali, 1 = Hanafi



  Future<void> setCalculationMethod(int method) async {
    calculationMethod.value = method;
    await _prefs.setInt('prayerCalcMethod', method);
    await fetchPrayerTimes();
  }

  Future<void> setAsrSchool(int school) async {
    asrSchool.value = school;
    await _prefs.setInt('prayerAsrSchool', school);
    await fetchPrayerTimes();
  }

  Future<void> _fetchPrayerTimesByCoords(double lat, double lng) async {
    try {
      final url = 'http://api.aladhan.com/v1/timings/${DateTime.now().toIso8601String().split('T')[0]}'
          '?latitude=$lat&longitude=$lng'
          '&method=${calculationMethod.value}'
          '&school=${asrSchool.value}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'] as Map<String, dynamic>;

        prayerTimes.clear();
        final prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        for (var name in prayerNames) {
          if (timings.containsKey(name)) {
            // API sometimes appends a timezone note like "05:12 (EAT)" — strip it.
            final raw = timings[name].toString();
            prayerTimes[name] = raw.split(' ').first;
          }
        }
      }
    } catch (e) {
      errorMessage.value = _friendlyError(e, fallback: 'Error fetching prayer times. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  // ==================== TASBIH ====================
  void incrementTasbih() {
    if (tasbihCount.value < tasbihTotal.value) {
      tasbihCount.value++;
    } else {
      tasbihCount.value = 0;
      Get.snackbar(
        'Tasbih Complete',
        'You have completed the tasbih! 🎉',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void resetTasbih() {
    tasbihCount.value = 0;
  }

  void changeTasbihType(String type) {
    tasbihType.value = type;
    resetTasbih();
  }

  void setTasbihTotal(double total) {
    tasbihTotal.value = total.toInt();
    resetTasbih();
  }

  // ==================== PRAYER TIMES & QIBLA BEARING ====================
  Future<void> fetchPrayerTimes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final location = await _getCurrentLocation();
      if (location == null) {
        errorMessage.value = 'Unable to get location. Using default coordinates.';
        _calculateQiblaBearing(21.4225, 39.8262);
        await _fetchPrayerTimesByCoords(21.4225, 39.8262); // Mecca fallback
        return;
      }

      currentLocation.value = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'; // remove this line
      _calculateQiblaBearing(location.latitude, location.longitude);
      await _reverseGeocode(location.latitude, location.longitude);
      await _fetchPrayerTimesByCoords(location.latitude, location.longitude);

    } catch (e) {
      errorMessage.value = _friendlyError(e, fallback: 'Error fetching prayer times. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Calculates real geographical bearing to Mecca (Kaaba)
  void _calculateQiblaBearing(double userLat, double userLng) {
    const double kaabaLat = 21.4225;
    const double kaabaLng = 39.8262;

    final double userLatRad = userLat * pi / 180;
    final double kaabaLatRad = kaabaLat * pi / 180;
    final double diffLngRad = (kaabaLng - userLng) * pi / 180;

    final double y = sin(diffLngRad);
    final double x = cos(userLatRad) * tan(kaabaLatRad) - sin(userLatRad) * cos(diffLngRad);

    double qibla = atan2(y, x) * 180 / pi;
    qiblaBearing.value = (qibla + 360) % 360;
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final city = p.locality?.isNotEmpty == true
            ? p.locality!
            : (p.subAdministrativeArea ?? p.administrativeArea ?? '');
        final country = p.country ?? '';
        currentLocation.value = [city, country].where((s) => s.isNotEmpty).join(', ');
        return;
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    }
    // Fallback if geocoding fails (e.g. offline)
    currentLocation.value = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }
  Future<Position?> _getCurrentLocation() async {
    try {
      final status = await Permission.location.status;

      if (status.isDenied || status.isRestricted) {
        final newStatus = await Permission.location.request();
        if (!newStatus.isGranted) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }


  var citySuggestions = <CitySuggestion>[].obs;
  var isSearchingCity = false.obs;
  var isManualLocation = false.obs; // true once user picks from search, so GPS refresh doesn't override it
  Timer? _searchDebounce;

  void searchCity(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      citySuggestions.clear();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _runCitySearch(query.trim()));
  }

  Future<void> _runCitySearch(String query) async {
    try {
      isSearchingCity.value = true;
      final url = 'https://nominatim.openstreetmap.org/search'
          '?q=${Uri.encodeQueryComponent(query)}&format=json&addressdetails=1&limit=8';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'YourAppName/1.0 (contact@yourapp.com)'},
      );

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        citySuggestions.value = results.map((r) {
          final addr = r['address'] ?? {};
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? r['name'] ?? '';
          final country = addr['country'] ?? '';
          final region = addr['state'] ?? '';
          final label = [city, if (region.isNotEmpty && region != city) region, country]
              .where((s) => s.toString().isNotEmpty)
              .join(', ');
          return CitySuggestion(
            displayName: label.isNotEmpty ? label : (r['display_name'] ?? ''),
            lat: double.parse(r['lat']),
            lon: double.parse(r['lon']),
          );
        }).toList();
      }
    } catch (e) {
      print('City search failed: $e');
    } finally {
      isSearchingCity.value = false;
    }
  }

  Future<void> selectCity(CitySuggestion city) async {
    citySuggestions.clear();
    isManualLocation.value = true;
    currentLocation.value = city.displayName;
    _calculateQiblaBearing(city.lat, city.lon);
    await _fetchPrayerTimesByCoords(city.lat, city.lon);
  }

  Future<void> useCurrentLocation() async {
    isManualLocation.value = false;
    await fetchPrayerTimes();
  }
  // ==================== REAL QIBLA COMPASS ====================
  // islamic_controller.dart
  Future<void> startQiblaCompass() async {
    try {
      _compassSubscription?.cancel();
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (event.heading != null) {
          isCompassAvailable.value = true;
          compassHeading.value = (event.heading! + 360) % 360;
        } else {
          isCompassAvailable.value = false; // e.g. no magnetometer / needs calibration
        }
      });

      if (FlutterCompass.events == null) {
        isCompassAvailable.value = false;
        Get.snackbar(
          'Compass Unavailable',
          'This device has no compass sensor.',
          colorText: Colors.white,
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      isCompassAvailable.value = false;
      Get.snackbar('Error', _friendlyError(e, fallback: 'Failed to start compass.'));
    }
  }

  // ==================== HIJRI CALENDAR ====================
  void _loadHijriDate() {
    final todayKey = DateTime.now().toIso8601String().split('T')[0];
    final savedDateKey = _prefs.getString('hijriDateDay');
    final saved = _prefs.getString('hijriDate');

    if (saved != null && savedDateKey == todayKey) {
      // Cached value is for today — use it, no need to hit the network.
      hijriDate.value = saved;
    } else {
      // Stale or missing — show something reasonable while we fetch.
      hijriDate.value = saved ?? '';
      _fetchTodayHijriDate(todayKey);
    }
    gregorianDate.value = DateTime.now().toLocal().toString().split(' ')[0];
  }

  Future<void> _fetchTodayHijriDate(String todayKey) async {
    try {
      final now = DateTime.now();
      final dd = now.day.toString().padLeft(2, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final url = 'https://api.aladhan.com/v1/gToH/$dd-$mm-${now.year}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hijri = data['data']['hijri'];
        hijriDate.value = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH';
        await _prefs.setString('hijriDate', hijriDate.value);
        await _prefs.setString('hijriDateDay', todayKey);
      }
    } catch (e) {
      print('Error fetching hijri date: $e');
      // Keep whatever was already showing (cached or empty) rather than
      // falling back to an incorrect manual calculation.
    }
  }

  Future<void> convertDate(DateTime date) async {
    try {
      final url = 'https://api.aladhan.com/v1/gToH/${date.year}/${date.month}/${date.day}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hijri = data['data']['hijri'];
        hijriDate.value = '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH';
        gregorianDate.value = date.toLocal().toString().split(' ')[0];
        _prefs.setString('hijriDate', hijriDate.value);
      }
    } catch (e) {
      print('Error converting date: $e');
    }
  }

  // ==================== QURAN ====================
  Future<void> loadQuran() async {
    try {
      isQuranLoading.value = true;
      quranData.value = List.generate(114, (index) {
        return {
          'surah': index + 1,
          'name': 'Surah ${index + 1}',
          'ayahs': 7,
        };
      });
    } catch (e) {
      print('Error loading Quran: $e');
    } finally {
      isQuranLoading.value = false;
    }
  }

  Future<String> getAyah(int surah, int ayah) async {
    try {
      final url = 'https://api.alquran.cloud/v1/ayah/$surah:$ayah/editions/quran-uthmani';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['text'] ?? '';
      }
      return '';
    } catch (e) {
      print('Error getting ayah: $e');
      return '';
    }
  }
}
// islamic_controller.dart

class CitySuggestion {
  final String displayName; // e.g. "Addis Ababa, Ethiopia"
  final double lat;
  final double lon;
  CitySuggestion({required this.displayName, required this.lat, required this.lon});
}
