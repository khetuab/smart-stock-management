import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/promotion_model.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/google_sheets_service.dart';
import 'auth_controller.dart';

class PromotionController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  AuthController get _auth => Get.find<AuthController>();
  final CloudinaryService _cloudinary = CloudinaryService();

  // ...existing fields unchanged...

  var isUploadingImage = false.obs;

  static PromotionController get to {
    if (Get.isRegistered<PromotionController>()) return Get.find<PromotionController>();
    return Get.put(PromotionController(), permanent: true);
  }

  var promotions = <PromotionModel>[].obs;
  var isLoading = false.obs;
  var filter = 'all'.obs; // all | active | expired | inactive

  static const List<String> _headers = [
    'id', 'title', 'description', 'imageUrl', 'linkType', 'linkUrl', 'buttonText',
    'discountCode', 'discountPercentage', 'validFrom', 'validUntil', 'priority',
    'isActive', 'views', 'clicks', 'createdAt',
  ];

  bool get isAdmin => _auth.isAdmin;

  @override
  void onInit() {
    super.onInit();
    loadPromotions();
  }

  /// Only banners a CUSTOMER should ever see — sorted so the ones the
  /// shop owner marked more important show first.
  List<PromotionModel> get liveBanners {
    final live = promotions.where((p) => p.isLive).toList();
    live.sort((a, b) => b.priority.compareTo(a.priority));
    return live;
  }

  List<PromotionModel> get filtered {
    switch (filter.value) {
      case 'active':
        return promotions.where((p) => p.isLive).toList();
      case 'expired':
        return promotions.where((p) => p.isExpired).toList();
      case 'inactive':
        return promotions.where((p) => !p.isActive).toList();
      default:
        return promotions;
    }
  }

  Future<void> loadPromotions() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Promotions');

      final data = await _sheets.getSheetDataWithHeaders('Promotions');
      promotions.value = _parse(data);
    } catch (e) {
      debugPrint('Error loading promotions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<PromotionModel> _parse(Map<String, List<dynamic>> data) {
    if (data.isEmpty) return [];
    List<dynamic> col(String key) => data[key] ?? [];
    String at(List<dynamic> c, int i) => i < c.length ? (c[i]?.toString() ?? '') : '';

    final ids = col('id');
    final list = <PromotionModel>[];

    for (int i = 0; i < ids.length; i++) {
      if (at(ids, i).isEmpty) continue;
      list.add(PromotionModel(
        id: at(ids, i),
        title: at(col('title'), i),
        description: at(col('description'), i),
        imageUrl: at(col('imageUrl'), i),
        linkType: at(col('linkType'), i).isEmpty ? 'web' : at(col('linkType'), i),
        linkUrl: at(col('linkUrl'), i),
        buttonText: at(col('buttonText'), i).isEmpty ? 'Learn More' : at(col('buttonText'), i),
        discountCode: at(col('discountCode'), i).isEmpty ? null : at(col('discountCode'), i),
        discountPercentage: double.tryParse(at(col('discountPercentage'), i)) ?? 0,
        validFrom: _parseFlexibleDate(at(col('validFrom'), i)) ?? DateTime(2000),
        validUntil: _parseFlexibleDate(at(col('validUntil'), i)) ?? DateTime(2100),
        priority: int.tryParse(at(col('priority'), i)) ?? 0,
        isActive: at(col('isActive'), i).toLowerCase() == 'true',
        views: int.tryParse(at(col('views'), i)) ?? 0,
        clicks: int.tryParse(at(col('clicks'), i)) ?? 0,
        createdAt: at(col('createdAt'), i),
      ));
    }
    return list;
  }
  /// Handles both a clean ISO string (what we write going forward, see
  /// `_asPlainText` below) AND Google Sheets' own auto-reformatted
  /// output for any OLDER rows — e.g. "2026-09-27 0:00:00" with an
  /// un-padded single-digit hour, which Dart's strict DateTime.parse
  /// rejects outright since ISO 8601 requires exactly two digits.
  DateTime? _parseFlexibleDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;

    final match = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})[ T]?(\d{1,2})?:?(\d{1,2})?:?(\d{1,2})?',
    ).firstMatch(trimmed);
    if (match == null) return null;

    final y = match.group(1)!;
    final mo = (match.group(2) ?? '1').padLeft(2, '0');
    final d = (match.group(3) ?? '1').padLeft(2, '0');
    final h = (match.group(4) ?? '0').padLeft(2, '0');
    final mi = (match.group(5) ?? '0').padLeft(2, '0');
    final s = (match.group(6) ?? '0').padLeft(2, '0');
    return DateTime.tryParse('$y-$mo-${d}T$h:$mi:$s');
  }
  /// A leading apostrophe tells Google Sheets "store this as plain text,
  /// don't auto-detect it as a date." Without this, Sheets silently
  /// reformats any ISO date-like string on write (dropping precision,
  /// un-padding single-digit hours) — which is exactly what caused every
  /// promotion to read back as instantly expired.
  String _asPlainText(String value) => "'$value";

  List<dynamic> _rowFor(PromotionModel p) => [
    p.id, p.title, p.description, p.imageUrl, p.linkType, p.linkUrl, p.buttonText,
    p.discountCode ?? '', p.discountPercentage,
    _asPlainText(p.validFrom.toIso8601String()),
    _asPlainText(p.validUntil.toIso8601String()),
    p.priority, p.isActive.toString(), p.views, p.clicks,
    _asPlainText(p.createdAt),
  ];

  Future<void> _persist(PromotionModel p) async {
    final rowIndex = await _sheets.findRowIndexById(sheetName: 'Promotions', idColumn: 'id', id: p.id);
    if (rowIndex != null) {
      await _sheets.updateRow(sheetName: 'Promotions', rowIndex: rowIndex, rowData: _rowFor(p));
    } else {
      await _sheets.appendToSheet(sheetName: 'Promotions', rowData: _rowFor(p), defaultHeaders: _headers);
    }
  }

  void _applyLocally(PromotionModel p) {
    final index = promotions.indexWhere((x) => x.id == p.id);
    if (index != -1) {
      promotions[index] = p;
    } else {
      promotions.add(p);
    }
  }

  // ==================== ADMIN-ONLY CRUD ====================
  Future<void> createPromotion(PromotionModel draft) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      final promo = PromotionModel(
        id: Helpers.generateId(),
        title: draft.title,
        description: draft.description,
        imageUrl: draft.imageUrl,
        linkType: draft.linkType,
        linkUrl: draft.linkUrl,
        buttonText: draft.buttonText,
        discountCode: draft.discountCode,
        discountPercentage: draft.discountPercentage,
        validFrom: draft.validFrom,
        validUntil: draft.validUntil,
        priority: draft.priority,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _persist(promo);
      _applyLocally(promo);
      Get.snackbar('Success', 'Promotion created'.tr, colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create promotion: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePromotion(PromotionModel updated) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      await _persist(updated);
      _applyLocally(updated);
      Get.snackbar('Success', 'Promotion updated'.tr, colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update promotion: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleStatus(PromotionModel p) async {
    if (!isAdmin) return;
    await updatePromotion(p.copyWith(isActive: !p.isActive));
  }

  Future<void> deletePromotion(String id) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      promotions.removeWhere((p) => p.id == id);
      final all = List<PromotionModel>.from(promotions);
      final values = <List<dynamic>>[_headers, ...all.map(_rowFor)];
      await _sheets.clearSheet('Promotions');
      await _sheets.writeToSheet(sheetName: 'Promotions', values: values);
      Get.snackbar('Success', 'Promotion deleted'.tr, colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete promotion: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== CUSTOMER-SIDE TRACKING ====================
  final Set<String> _viewedThisSession = {};

  Future<void> trackView(PromotionModel p) async {
    if (_viewedThisSession.contains(p.id)) return; // one view per session, not per rebuild
    _viewedThisSession.add(p.id);
    final updated = p.copyWith(views: p.views + 1);
    _applyLocally(updated); // instant UI update
    await _persist(updated);
  }

  Future<String?> uploadBannerImage({required bool fromCamera}) async {
    try {
      isUploadingImage.value = true;
      final url = fromCamera
          ? await _cloudinary.uploadFromCamera(folder: 'promotion_banners', isPublic: true)
          : await _cloudinary.uploadFromGallery(folder: 'promotion_banners', isPublic: true);

      if (url == null) {
        Get.snackbar('Error', 'Failed to upload image'.tr, colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
      }
      return url;
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> handleTap(PromotionModel p) async {
    final updated = p.copyWith(clicks: p.clicks + 1);
    _applyLocally(updated);
    unawaited(_persist(updated));

    if (p.linkType == 'none' || p.linkUrl.trim().isEmpty) return;
    String url = p.linkUrl.trim();
    if (!url.startsWith('http') && !url.startsWith('mailto:') && !url.startsWith('tel:')) {
      url = 'https://$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> refresh() => loadPromotions();
}

void unawaited(Future<void> future) {}