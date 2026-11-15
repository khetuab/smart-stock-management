import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/error_helper.dart';
import '../../data/services/google_sheets_service.dart';
import 'auth_controller.dart';

/// Sheet columns: whatsapp, telegram, instagram, facebook, tiktok, youtube,
/// updatedAt, youtubeHandle, youtubeApiKey, tiktokFeed, instagramFeed, facebookFeed.
/// Every platform cell may hold several links separated by '|'.
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
  var youtubeHandle = ''.obs;
  var youtubeApiKey = ''.obs;

  /// RSS / Atom / JSON Feed URLs used to read latest posts.
  var tiktokFeed = ''.obs;
  var instagramFeed = ''.obs;
  var facebookFeed = ''.obs;

  var isLoading = false.obs;

  static const List<String> _headers = [
    'whatsapp', 'telegram', 'instagram', 'facebook', 'tiktok', 'youtube',
    'updatedAt', 'youtubeHandle', 'youtubeApiKey',
    'tiktokFeed', 'instagramFeed', 'facebookFeed',
  ];

  bool get isAdmin => _auth.isAdmin;

  bool get canFetchYouTubeFeed =>
      youtubeHandle.value.trim().isNotEmpty && youtubeApiKey.value.trim().isNotEmpty;

  // ── multi-link helpers ──

  static List<String> split(String raw) =>
      raw.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  RxString _linkRx(String platform) {
    switch (platform) {
      case 'whatsapp': return whatsapp;
      case 'telegram': return telegram;
      case 'instagram': return instagram;
      case 'facebook': return facebook;
      case 'tiktok': return tiktok;
      default: return youtube;
    }
  }

  /// All profile links of a platform (for "Open channel").
  List<String> linksFor(String platform) => split(_linkRx(platform).value);

  /// First link, or '' — use this anywhere a single URL is needed.
  String firstLink(String platform) {
    final l = linksFor(platform);
    return l.isEmpty ? '' : l.first;
  }

  /// The observable the live feed depends on: YouTube and Telegram read the
  /// channel link itself; the others read a separate feed URL.
  RxString feedRxFor(String platform) {
    switch (platform) {
      case 'tiktok': return tiktokFeed;
      case 'instagram': return instagramFeed;
      case 'facebook': return facebookFeed;
      default: return _linkRx(platform);
    }
  }

  List<String> feedSourcesFor(String platform) => split(feedRxFor(platform).value);

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
      String at(String key) =>
          (data[key]?.isNotEmpty ?? false) ? (data[key]!.last?.toString() ?? '') : '';

      whatsapp.value = at('whatsapp');
      telegram.value = at('telegram');
      instagram.value = at('instagram');
      facebook.value = at('facebook');
      tiktok.value = at('tiktok');
      youtube.value = at('youtube');
      youtubeHandle.value = at('youtubeHandle');
      youtubeApiKey.value = at('youtubeApiKey');
      tiktokFeed.value = at('tiktokFeed');
      instagramFeed.value = at('instagramFeed');
      facebookFeed.value = at('facebookFeed');
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
    String youtubeHandle = '',
    String youtubeApiKey = '',
    String tiktokFeed = '',
    String instagramFeed = '',
    String facebookFeed = '',
  }) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('SocialLinks');

      final row = [
        whatsapp.trim(), telegram.trim(), instagram.trim(),
        facebook.trim(), tiktok.trim(), youtube.trim(),
        DateTime.now().toIso8601String(),
        youtubeHandle.trim(), youtubeApiKey.trim(),
        tiktokFeed.trim(), instagramFeed.trim(), facebookFeed.trim(),
      ];
      await _sheets.clearSheet('SocialLinks');
      await _sheets.writeToSheet(sheetName: 'SocialLinks', values: [_headers, row]);

      this.whatsapp.value = whatsapp.trim();
      this.telegram.value = telegram.trim();
      this.instagram.value = instagram.trim();
      this.facebook.value = facebook.trim();
      this.tiktok.value = tiktok.trim();
      this.youtube.value = youtube.trim();
      this.youtubeHandle.value = youtubeHandle.trim();
      this.youtubeApiKey.value = youtubeApiKey.trim();
      this.tiktokFeed.value = tiktokFeed.trim();
      this.instagramFeed.value = instagramFeed.trim();
      this.facebookFeed.value = facebookFeed.trim();

      Get.snackbar('Success', 'Social links updated'.tr,
          colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Failed to save social links: $e');
      Get.snackbar('Error', 'Failed to save social links: ${ErrorHelper.friendly(e)}',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// One (first) link per filled-in platform, for icons that open a single URL.
  List<MapEntry<String, String>> get activeLinks {
    const platforms = ['whatsapp', 'telegram', 'instagram', 'facebook', 'tiktok', 'youtube'];
    return [
      for (final p in platforms)
        if (firstLink(p).isNotEmpty) MapEntry(p, firstLink(p)),
    ];
  }
}