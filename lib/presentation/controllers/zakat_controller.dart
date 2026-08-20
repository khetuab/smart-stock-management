import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/models/product_model.dart';

class ZakatController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();

  var isLoading = false.obs;
  var isZakatEnabled = false.obs;

  // Assets
  var inventoryValue = 0.0.obs;
  var cashBalance = 0.0.obs;
  var bankBalance = 0.0.obs;
  var goldValue = 0.0.obs;
  var silverValue = 0.0.obs;
  var otherAssets = 0.0.obs;

  // Calculations
  var totalAssets = 0.0.obs;
  var nisabThreshold = 0.0.obs;
  var isAboveNisab = false.obs;
  var zakatDue = 0.0.obs;

  // Input fields
  var cashInput = ''.obs;
  var bankInput = ''.obs;
  var goldInput = ''.obs;
  var silverInput = ''.obs;
  var otherAssetsInput = ''.obs;

  @override
  void onInit() {
    super.onInit();
    refreshZakatData();
  }

  @override
  void onReady() {
    super.onReady();
    // 🚨 Ensure state refreshes whenever the controller becomes ready
    refreshZakatData();
  }

  /// Refreshes Zakat state and reloads inventory data if enabled
  Future<void> refreshZakatData() async {
    // Read directly from SharedPreferences
    final enabled = _prefs.isZakatEnabled();
    isZakatEnabled.value = enabled;

    print('🔄 [ZAKAT] Refreshing - Enabled: $enabled');

    if (enabled) {
      await loadInventoryValue();
    } else {
      // Clear data when disabled
      inventoryValue.value = 0.0;
      cashBalance.value = 0.0;
      bankBalance.value = 0.0;
      goldValue.value = 0.0;
      silverValue.value = 0.0;
      otherAssets.value = 0.0;
      totalAssets.value = 0.0;
      zakatDue.value = 0.0;
      isAboveNisab.value = false;
      cashInput.value = '';
      bankInput.value = '';
      goldInput.value = '';
      silverInput.value = '';
      otherAssetsInput.value = '';
    }
  }


  void checkZakatStatus() {
    // Read directly from SharedPreferences
    isZakatEnabled.value = _prefs.isZakatEnabled();
    print('🔍 [ZAKAT] checkZakatStatus: ${isZakatEnabled.value}');
  }

  Future<void> loadInventoryValue() async {
    checkZakatStatus();
    if (!isZakatEnabled.value) return;

    try {
      isLoading.value = true;
      await _sheets.init();

      final data = await _sheets.getSheetDataWithHeaders('Products');
      final products = _parseProducts(data);

      inventoryValue.value = products.fold(0.0, (sum, product) {
        return sum + (product.purchasePrice * product.quantity);
      });

      // Load saved values from Google Sheets
      await loadSavedValues();

    } catch (e) {
      print('Error loading inventory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Product> _parseProducts(Map<String, List<dynamic>> data) {
    final products = <Product>[];
    if (data.isEmpty) return products;

    // Extract list references cleanly with default fallback to empty lists
    final ids = data['id'] ?? [];
    final names = data['name'] ?? [];
    final categories = data['category'] ?? [];
    final images = data['image'] ?? [];
    final purchasePrices = data['purchasePrice'] ?? [];
    final sellingPrices = data['sellingPrice'] ?? [];
    final quantities = data['quantity'] ?? [];
    final minQuantities = data['minQuantity'] ?? [];
    final barcodes = data['barcode'] ?? [];
    final descriptions = data['description'] ?? [];
    final dates = data['dateAdded'] ?? [];

    for (int i = 0; i < names.length; i++) {
      products.add(
        Product(
          id: i < ids.length ? ids[i]?.toString() ?? '' : '',
          name: names[i]?.toString() ?? '',
          category: i < categories.length ? categories[i]?.toString() ?? '' : '',
          image: i < images.length ? images[i]?.toString() ?? '' : '',
          purchasePrice: i < purchasePrices.length
              ? double.tryParse(purchasePrices[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          sellingPrice: i < sellingPrices.length
              ? double.tryParse(sellingPrices[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          quantity: i < quantities.length
              ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          minQuantity: i < minQuantities.length
              ? double.tryParse(minQuantities[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          barcode: i < barcodes.length ? barcodes[i]?.toString() ?? '' : '',
          description: i < descriptions.length ? descriptions[i]?.toString() ?? '' : '',
          dateAdded: i < dates.length ? dates[i]?.toString() ?? '' : '',
        ),
      );
    }

    return products;
  }
  Future<void> loadSavedValues() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Zakat');
      if (data.isEmpty) {
        await saveZakatData();
        return;
      }

      final cashData = data['cash'] ?? [];
      final bankData = data['bank'] ?? [];
      final goldData = data['gold'] ?? [];
      final silverData = data['silver'] ?? [];
      final otherData = data['otherAssets'] ?? [];

      if (cashData.isNotEmpty) {
        cashBalance.value = double.tryParse(cashData.last?.toString() ?? '0') ?? 0.0;
        cashInput.value = cashBalance.value.toString();
      }

      if (bankData.isNotEmpty) {
        bankBalance.value = double.tryParse(bankData.last?.toString() ?? '0') ?? 0.0;
        bankInput.value = bankBalance.value.toString();
      }

      if (goldData.isNotEmpty) {
        goldValue.value = double.tryParse(goldData.last?.toString() ?? '0') ?? 0.0;
        goldInput.value = goldValue.value.toString();
      }

      if (silverData.isNotEmpty) {
        silverValue.value = double.tryParse(silverData.last?.toString() ?? '0') ?? 0.0;
        silverInput.value = silverValue.value.toString();
      }

      if (otherData.isNotEmpty) {
        otherAssets.value = double.tryParse(otherData.last?.toString() ?? '0') ?? 0.0;
        otherAssetsInput.value = otherAssets.value.toString();
      }

      calculateZakat();

    } catch (e) {
      print('Error loading zakat data: $e');
    }
  }

  void calculateZakat() {
    cashBalance.value = double.tryParse(cashInput.value) ?? 0.0;
    bankBalance.value = double.tryParse(bankInput.value) ?? 0.0;
    goldValue.value = double.tryParse(goldInput.value) ?? 0.0;
    silverValue.value = double.tryParse(silverInput.value) ?? 0.0;
    otherAssets.value = double.tryParse(otherAssetsInput.value) ?? 0.0;

    totalAssets.value = inventoryValue.value +
        cashBalance.value +
        bankBalance.value +
        goldValue.value +
        silverValue.value +
        otherAssets.value;

    nisabThreshold.value = 50000.0;
    isAboveNisab.value = totalAssets.value >= nisabThreshold.value;

    if (isAboveNisab.value) {
      zakatDue.value = totalAssets.value * 0.025;
    } else {
      zakatDue.value = 0.0;
    }
  }

  Future<void> saveZakatData() async {
    try {
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Zakat');

      final headers = ['timestamp', 'cash', 'bank', 'gold', 'silver', 'otherAssets', 'totalAssets', 'zakatDue'];
      final values = [
        headers,
        [
          DateTime.now().toIso8601String(),
          cashBalance.value,
          bankBalance.value,
          goldValue.value,
          silverValue.value,
          otherAssets.value,
          totalAssets.value,
          zakatDue.value,
        ]
      ];

      await _sheets.clearSheet('Zakat');
      await _sheets.writeToSheet(
        sheetName: 'Zakat',
        values: values,
      );

      Get.snackbar(
        'Success',
        'Zakat data saved successfully',
        colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM
      );

    } catch (e) {
      print('Error saving zakat data: $e');
      Get.snackbar(
        'Error',
        'Failed to save zakat data: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM
      );
    }
  }

  void updateCash(String value) {
    cashInput.value = value;
    calculateZakat();
  }

  void updateBank(String value) {
    bankInput.value = value;
    calculateZakat();
  }

  void updateGold(String value) {
    goldInput.value = value;
    calculateZakat();
  }

  void updateSilver(String value) {
    silverInput.value = value;
    calculateZakat();
  }

  void updateOtherAssets(String value) {
    otherAssetsInput.value = value;
    calculateZakat();
  }
}