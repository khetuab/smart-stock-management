import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance = SharedPreferencesService._internal();
  factory SharedPreferencesService() => _instance;
  SharedPreferencesService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic methods
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  Future<void> setList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  List<String>? getList(String key) {
    return _prefs.getStringList(key);
  }

  Future<void> setMap(String key, Map<String, dynamic> value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getMap(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  // Auth methods
  bool isLoggedIn() {
    return _prefs.getBool(StorageKeys.isLoggedIn) ?? false;
  }

  String? getUsername() {
    return _prefs.getString(StorageKeys.username);
  }

  Future<void> saveLoginSession(String username) async {
    await _prefs.setBool(StorageKeys.isLoggedIn, true);
    await _prefs.setString(StorageKeys.username, username);
  }

  Future<void> clearLoginSession() async {
    await _prefs.setBool(StorageKeys.isLoggedIn, false);
    await _prefs.remove(StorageKeys.username);
  }

  // Store info methods
  bool isSetupCompleted() {
    return _prefs.getBool(StorageKeys.setupCompleted) ?? false;
  }

  String? getStoreName() {
    return _prefs.getString(StorageKeys.storeName);
  }

  String? getStoreLogo() {
    return _prefs.getString(StorageKeys.storeLogo);
  }

  String? getThemeColor() {
    return _prefs.getString(StorageKeys.themeColor);
  }

  String? getCurrency() {
    return _prefs.getString(StorageKeys.currency);
  }

  String? getLanguage() {
    return _prefs.getString(StorageKeys.language);
  }

  bool isZakatEnabled() {
    return _prefs.getBool(StorageKeys.zakatEnabled) ?? false;
  }

  Future<void> saveStoreInfo({
    required String storeName,
    required String storeLogo,
    required String themeColor,
    required String currency,
    required String language,
    required bool zakatEnabled,
    required String ownerName,
  }) async {
    await _prefs.setString(StorageKeys.storeName, storeName);
    await _prefs.setString(StorageKeys.storeLogo, storeLogo);
    await _prefs.setString(StorageKeys.themeColor, themeColor);
    await _prefs.setString(StorageKeys.currency, currency);
    await _prefs.setString(StorageKeys.language, language);
    await _prefs.setBool(StorageKeys.zakatEnabled, zakatEnabled);
    await _prefs.setString(StorageKeys.ownerName, ownerName);
    await _prefs.setBool(StorageKeys.setupCompleted, true);
  }
}