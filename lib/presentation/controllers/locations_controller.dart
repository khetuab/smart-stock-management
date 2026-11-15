import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/store_location_model.dart';
import '../../data/services/google_sheets_service.dart';
import 'auth_controller.dart';

/// CRUD + stream of physical branch locations pinned on the Ethiopia map.
///
/// Backend: a NEW 'StoreLocations' sheet (id, name, city, region, lat, lng,
/// phone, hours, address, isMain, createdAt). No existing sheet is touched,
/// so this is 100% additive to the current business data.
///
/// When the sheet has no rows yet the controller serves the built-in mock
/// branches so the map is never empty; as soon as the owner saves real
/// locations from the admin panel, the sheet wins.
class LocationsController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  AuthController get _auth => Get.find<AuthController>();
  bool get isAdmin => _auth.isAdmin;

  static const List<String> headers = [
    'id', 'name', 'city', 'region', 'lat', 'lng',
    'phone', 'hours', 'address', 'isMain', 'createdAt',
  ];

  static const String sheetName = 'StoreLocations';

  static LocationsController get to {
    if (Get.isRegistered<LocationsController>()) return Get.find<LocationsController>();
    return Get.put(LocationsController(), permanent: true);
  }

  var locations = <StoreLocation>[].obs;
  var isLoading = false.obs;
  var selectedLocation = Rxn<StoreLocation>();
  var usingMockData = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLocations();
  }

  /// Locations actually shown on the map — sheet rows, or the seeded mocks.
  List<StoreLocation> get displayLocations =>
      locations.isEmpty ? kMockStoreLocations : locations;

  bool get isUsingMocks => locations.isEmpty;

  StoreLocation? get mainBranch {
    final all = displayLocations;
    for (final l in all) {
      if (l.isMain) return l;
    }
    return all.isEmpty ? null : all.first;
  }

  Future<void> loadLocations() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists(sheetName);
      await _ensureHeaders();

      final data = await _sheets.getSheetDataWithHeaders(sheetName);
      final parsed = _parseLocations(data);
      // Main branch first, then alphabetical by city.
      parsed.sort((a, b) {
        if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
        return a.city.toLowerCase().compareTo(b.city.toLowerCase());
      });
      locations.assignAll(parsed);
      usingMockData.value = parsed.isEmpty;
    } catch (e) {
      debugPrint('Error loading store locations: $e');
      usingMockData.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _ensureHeaders() async {
    final existing = await _sheets.getSheetDataWithHeaders(sheetName);
    if (existing.isEmpty) {
      await _sheets.writeToSheet(sheetName: sheetName, values: [headers]);
    }
  }

  List<StoreLocation> _parseLocations(Map<String, List<dynamic>> data) {
    final list = <StoreLocation>[];
    if (data.isEmpty) return list;

    List<dynamic> col(String key) => data[key] ?? [];
    String at(List<dynamic> c, int i) => i < c.length ? (c[i]?.toString() ?? '') : '';

    final ids = col('id');
    final names = col('name');
    final cities = col('city');
    final regions = col('region');
    final lats = col('lat');
    final lngs = col('lng');
    final phones = col('phone');
    final hours = col('hours');
    final addresses = col('address');
    final isMains = col('isMain');
    final createdAts = col('createdAt');

    for (int i = 0; i < names.length; i++) {
      final name = at(names, i);
      if (name.isEmpty) continue;
      list.add(StoreLocation(
        id: at(ids, i),
        name: name,
        city: at(cities, i),
        region: at(regions, i),
        lat: double.tryParse(at(lats, i)) ?? 9.03,
        lng: double.tryParse(at(lngs, i)) ?? 38.74,
        phone: at(phones, i),
        hours: at(hours, i),
        address: at(addresses, i),
        isMain: at(isMains, i) == '1',
        createdAt: at(createdAts, i),
      ));
    }
    return list;
  }

  Future<void> addLocation({
    required String name,
    required String city,
    required String region,
    required double lat,
    required double lng,
    String phone = '',
    String hours = '',
    String address = '',
    bool isMain = false,
  }) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists(sheetName);
      await _ensureHeaders();

      // Only one main branch — demote the previous one.
      if (isMain) {
        for (int i = 0; i < locations.length; i++) {
          if (locations[i].isMain) {
            locations[i] = locations[i].copyWith(isMain: false);
          }
        }
      }

      final loc = StoreLocation(
        id: Helpers.generateId(),
        name: name.trim(),
        city: city.trim(),
        region: region.trim(),
        lat: lat,
        lng: lng,
        phone: phone.trim(),
        hours: hours.trim(),
        address: address.trim(),
        isMain: isMain,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _sheets.appendToSheet(sheetName: sheetName, rowData: loc.toRow());
      locations.add(loc);
      _resort();

      Get.snackbar('Success', 'Location added successfully'.tr,
          colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add location: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateLocation(StoreLocation updated) async {
    if (!isAdmin) return;
    try {
      isLoading.value = true;
      final index = locations.indexWhere((l) => l.id == updated.id);
      if (index == -1) return;

      if (updated.isMain) {
        for (int i = 0; i < locations.length; i++) {
          if (locations[i].id != updated.id && locations[i].isMain) {
            locations[i] = locations[i].copyWith(isMain: false);
          }
        }
      }

      locations[index] = updated;
      await _rewriteAll();
      _resort();
      Get.snackbar('Success', 'Location updated successfully'.tr,
          colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      await loadLocations();
      Get.snackbar('Error', 'Failed to update location: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteLocation(StoreLocation loc) async {
    if (!isAdmin) return;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Delete Location'.tr),
        content: Text('Are you sure you want to delete "${loc.name}"?'.trParams({'name': loc.name})),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      isLoading.value = true;
      locations.removeWhere((l) => l.id == loc.id);
      await _rewriteAll();
      _resort();
      Get.snackbar('Deleted', 'Location removed.'.tr,
          colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      await loadLocations();
      Get.snackbar('Error', 'Failed to delete location: $e',
          colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _resort() {
    final list = locations.toList();
    list.sort((a, b) {
      if (a.isMain != b.isMain) return a.isMain ? -1 : 1;
      return a.city.toLowerCase().compareTo(b.city.toLowerCase());
    });
    locations.assignAll(list);
  }

  Future<void> _rewriteAll() async {
    final values = [
      headers,
      ...locations.map((l) => l.toRow()),
    ];
    await _sheets.writeToSheet(sheetName: sheetName, values: values);
  }

  void select(StoreLocation? loc) => selectedLocation.value = loc;
}
