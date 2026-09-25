import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import 'auth_controller.dart';

class SocialLinksController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  AuthController get _auth => Get.find<AuthController>();

  static SocialLinksController get to {
    if (Get.isRegistered<SocialLinksController>()) return Get.find<SocialLinksController>();
    return Get.put(SocialLinksController(), permanent: true);
  }

  var whatsapp = ''.obs;
  var telegram = ''.obs;
  var instagram = ''.obs;
  var facebook = ''.obs;
  var tiktok = ''.obs;
  var youtube = ''.obs;
  var isLoading = false.obs;

  static const List<String> _headers = ['whatsapp', 'telegram', 'instagram', 'facebook', 'tiktok','youtube', 'updatedAt'];

  bool get isAdmin => _auth.isAdmin;

  @override
  void onInit() {
    super.onInit();
    loadLinks();
  }

  Future<void> loadLinks() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('SocialLinks');

      final data = await _sheets.getSheetDataWithHeaders('SocialLinks');
      String at(String key) => (data[key]?.isNotEmpty ?? false) ? (data[key]!.last?.toString() ?? '') : '';

      whatsapp.value = at('whatsapp');
      telegram.value = at('telegram');
      instagram.value = at('instagram');
      facebook.value = at('facebook');
      tiktok.value = at('tiktok');
      youtube.value = at('youtube');
    } catch (e) {
      debugPrint('Error loading social links: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveLinks({
    required String whatsapp,
    required String telegram,
    required String instagram,
    required String facebook,
    required String tiktok,
    required String youtube,
  }) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('SocialLinks');

      final row = [whatsapp.trim(), telegram.trim(), instagram.trim(), facebook.trim(), tiktok.trim(),youtube.trim(), DateTime.now().toIso8601String()];
      await _sheets.clearSheet('SocialLinks');
      await _sheets.writeToSheet(sheetName: 'SocialLinks', values: [_headers, row]);

      this.whatsapp.value = whatsapp.trim();
      this.telegram.value = telegram.trim();
      this.instagram.value = instagram.trim();
      this.facebook.value = facebook.trim();
      this.tiktok.value = tiktok.trim();
      this.youtube.value = youtube.trim();

      Get.snackbar('Success', 'Social links updated'.tr, colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save social links: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Only the platforms the admin has actually filled in — an empty URL
  /// means "don't show this icon at all" rather than showing a dead link.
  List<MapEntry<String, String>> get activeLinks {
    final map = {
      'whatsapp': whatsapp.value,
      'telegram': telegram.value,
      'instagram': instagram.value,
      'facebook': facebook.value,
      'tiktok': tiktok.value,
      'youtube': youtube.value,
    };
    return map.entries.where((e) => e.value.trim().isNotEmpty).toList();
  }
}