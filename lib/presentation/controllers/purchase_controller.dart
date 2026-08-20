import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/purchase_model.dart';
import '../../core/utils/helpers.dart';
import 'debt_controller.dart';
import 'product_controller.dart';

class PurchaseController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final ProductController _productController = Get.find<ProductController>();

  // Purchase list
  var purchases = <Purchase>[].obs;
  var filteredPurchases = <Purchase>[].obs;
  var isLoading = false.obs;

  // Purchase form
  var selectedProduct = Rxn<Product>();
  var purchaseQuantity = 1.0.obs;
  var purchasePrice = 0.0.obs;
  var supplier = ''.obs;
  var searchQuery = ''.obs;
  var isCreditPurchase = false.obs;

  // Purchase history filters
  var selectedDateFilter = 'All'.obs;

  // in purchase_controller.dart
  static PurchaseController get to {
    if (Get.isRegistered<PurchaseController>()) return Get.find<PurchaseController>();
    return Get.put(PurchaseController(), permanent: true);
  }

  double get totalCreditOutstanding => purchases
      .where((p) => p.isCredit && p.balanceDue > 0)
      .fold(0.0, (sum, p) => sum + p.balanceDue);
  @override
  void onInit() {
    super.onInit();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      isLoading.value = true;
      await _sheets.init();

      final data = await _sheets.getSheetDataWithHeaders('Purchases');
      purchases.value = _parsePurchases(data);
      applyPurchaseFilters();

    } catch (e) {
      print('Error loading purchases: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Purchase> _parsePurchases(Map<String, List<dynamic>> data) {
    final purchases = <Purchase>[];
    if (data.isEmpty) return purchases;

    final ids = data['id'] ?? [];
    final productIds = data['productId'] ?? [];
    final productNames = data['productName'] ?? [];
    final quantities = data['quantity'] ?? [];
    final purchasePrices = data['purchasePrice'] ?? [];
    final totals = data['total'] ?? [];
    final suppliers = data['supplier'] ?? [];
    final dates = data['date'] ?? [];
    final times = data['time'] ?? [];
    final isCredits = data['isCredit'] ?? [];
    final amountPaids = data['amountPaid'] ?? [];

    for (int i = 0; i < ids.length; i++) {
      final total = i < totals.length ? double.tryParse(totals[i]?.toString() ?? '0') ?? 0.0 : 0.0;
      final isCredit = i < isCredits.length && (isCredits[i]?.toString().toLowerCase() == 'true');

      purchases.add(Purchase(
        id: ids[i]?.toString() ?? '',
        productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
        productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
        quantity: i < quantities.length ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        purchasePrice: i < purchasePrices.length ? double.tryParse(purchasePrices[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        total: total,
        supplier: i < suppliers.length ? suppliers[i]?.toString() ?? '' : '',
        date: i < dates.length ? dates[i]?.toString() ?? '' : '',
        time: i < times.length ? times[i]?.toString() ?? '' : '',
        isCredit: isCredit,
        amountPaid: i < amountPaids.length
            ? double.tryParse(amountPaids[i]?.toString() ?? '0') ?? (isCredit ? 0.0 : total)
            : (isCredit ? 0.0 : total),
      ));
    }
    return purchases;
  }

  Future<void> addPurchase() async {
    if (selectedProduct.value == null) {
      Get.snackbar('Error', 'Please select a product',
          colorText: Colors.red,  snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (purchaseQuantity.value <= 0) {
      Get.snackbar('Invalid Quantity', 'Please enter a valid quantity',
          colorText: Colors.orange,  snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (purchasePrice.value <= 0) {
      Get.snackbar('Invalid Price', 'Please enter a valid purchase price',
          colorText: Colors.orange,  snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (isCreditPurchase.value && supplier.value.trim().isEmpty) {
      Get.snackbar('Supplier Required', 'Enter a supplier name for a credit purchase',
          colorText: Colors.orange,  snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      await _sheets.init();

      final product = selectedProduct.value!;
      final now = DateTime.now();
      final purchaseId = Helpers.generateId();
      final total = purchaseQuantity.value * purchasePrice.value;
      final creditNow = isCreditPurchase.value;

      final purchase = Purchase(
        id: purchaseId,
        productId: product.id,
        productName: product.name,
        quantity: purchaseQuantity.value,
        purchasePrice: purchasePrice.value,
        total: total,
        supplier: supplier.value,
        date: now.toIso8601String().split('T')[0],
        time: now.toIso8601String().split('T')[1].substring(0, 8),
        isCredit: creditNow,
        amountPaid: creditNow ? 0.0 : total,
      );

      // Before appending rows in addPurchase():
      final existingPurchasesData = await _sheets.getSheetDataWithHeaders('Purchases');
      if (existingPurchasesData.isEmpty) {
        await _sheets.writeToSheet(
          sheetName: 'Purchases',
          values: [[
            'id', 'productId', 'productName', 'quantity', 'purchasePrice',
            'total', 'supplier', 'date', 'time', 'isCredit', 'amountPaid'
          ]],
        );
      }
      await _sheets.appendToSheet(
        sheetName: 'Purchases',
        rowData: [
          purchase.id.toString(),
          purchase.productId.toString(),
          purchase.productName.toString(),
          purchase.quantity.toString(),
          purchase.purchasePrice.toString(),
          purchase.total.toString(),
          purchase.supplier.toString(),
          purchase.date.toString(),
          purchase.time.toString(),
          purchase.isCredit.toString(),      // isCredit
          purchase.amountPaid.toString(),    // amountPaid
        ],
      );

      final updatedProduct = product.copyWith(
        quantity: product.quantity + purchaseQuantity.value,
        purchasePrice: purchasePrice.value,
      );
      await _updateProductQuantity(updatedProduct);

      final index = _productController.products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _productController.products[index] = updatedProduct;
      }

      purchases.add(purchase);
      applyPurchaseFilters();

      // If bought on credit, log it as a payable in the Debts ledger
      if (creditNow) {
        final debtController = Get.find<DebtController>();
        await debtController.addDebt(
          type: 'payable',
          refId: purchaseId,
          personName: supplier.value,
          totalAmount: total,
          amountPaid: 0.0,
          notes: '${purchase.quantity} unit(s) of ${product.name}',
        );
      }

      clearForm();

      if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar('Success', 'Purchase added successfully',
          colorText: Colors.green,  snackPosition: SnackPosition.BOTTOM);

    } catch (e, stack) {
      print('Error adding purchase: $e');
      print('Stacktrace: $stack');
      Get.snackbar('Error', 'Failed to add purchase: $e',
          colorText: Colors.red,  snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCreditPurchase(bool value) {
    isCreditPurchase.value = value;
  }

  Future<void> _updateProductQuantity(Product product) async {
    final allProducts = _productController.products.map((p) => p.toMap()).toList();
    final index = allProducts.indexWhere((p) => p['id'] == product.id);
    if (index != -1) {
      allProducts[index] = product.toMap();
    }

    final headers = ['id', 'name', 'category', 'image', 'purchasePrice', 'sellingPrice', 'quantity', 'minQuantity', 'barcode', 'description', 'dateAdded'];
    final values = <List<dynamic>>[headers];

    for (var p in allProducts) {
      values.add([
        p['id']?.toString() ?? '',
        p['name']?.toString() ?? '',
        p['category']?.toString() ?? 'General',
        p['image']?.toString() ?? '',
        p['purchasePrice']?.toString() ?? '0',
        p['sellingPrice']?.toString() ?? '0',
        p['quantity']?.toString() ?? '0',
        p['minQuantity']?.toString() ?? '0',
        p['barcode']?.toString() ?? '',
        p['description']?.toString() ?? '',
        p['dateAdded']?.toString() ?? '',
      ]);
    }

    await _sheets.writeToSheet(
      sheetName: 'Products',
      values: values,
    );
  }

  void searchPurchases(String query) {
    searchQuery.value = query;
    applyPurchaseFilters();
  }

  void applyPurchaseFilters() {
    var filtered = List<Purchase>.from(purchases);

    // Date filter
    if (selectedDateFilter.value != 'All') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (selectedDateFilter.value) {
        case 'Today':
          filtered = filtered.where((p) {
            final parsedDate = DateTime.tryParse(p.date);
            if (parsedDate == null) return false;
            return DateTime(parsedDate.year, parsedDate.month, parsedDate.day)
                .isAtSameMomentAs(today);
          }).toList();
          break;
        case 'This Week':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          filtered = filtered.where((p) {
            final parsedDate = DateTime.tryParse(p.date);
            if (parsedDate == null) return false;
            return parsedDate.isAfter(weekStart.subtract(const Duration(seconds: 1)));
          }).toList();
          break;
        case 'This Month':
          final monthStart = DateTime(now.year, now.month, 1);
          filtered = filtered.where((p) {
            final parsedDate = DateTime.tryParse(p.date);
            if (parsedDate == null) return false;
            return parsedDate.isAfter(monthStart.subtract(const Duration(seconds: 1)));
          }).toList();
          break;
      }
    }

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((p) =>
      p.productName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.supplier.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }

    filteredPurchases.value = filtered;
  }

  void setDateFilter(String filter) {
    selectedDateFilter.value = filter;
    applyPurchaseFilters();
  }

  void clearForm() {
    selectedProduct.value = null;
    purchaseQuantity.value = 1.0;
    purchasePrice.value = 0.0;
    supplier.value = '';
    isCreditPurchase.value = false;
  }

  /// Called by DebtController when a payment is recorded against a
  /// credit purchase. Patches ONLY the matching row's amountPaid,
  /// preserving every other row exactly as stored.
  Future<void> applyDebtPayment(String purchaseId, double amount) async {
    try {
      await _sheets.init();
      final data = await _sheets.getSheetDataWithHeaders('Purchases');
      if (data.isEmpty) return;

      final ids = data['id'] ?? [];
      final headers = [
        'id', 'productId', 'productName', 'quantity', 'purchasePrice',
        'total', 'supplier', 'date', 'time', 'isCredit', 'amountPaid',
      ];
      final values = <List<dynamic>>[headers];

      double? finalPaidForMemoryUpdate;

      for (int i = 0; i < ids.length; i++) {
        final rowId = ids[i]?.toString() ?? '';
        final total = double.tryParse((data['total'] ?? [])[i]?.toString() ?? '0') ?? 0.0;
        double paid = double.tryParse((data['amountPaid'] ?? [])[i]?.toString() ?? '0') ?? 0.0;

        if (rowId == purchaseId) {
          paid = (paid + amount).clamp(0.0, total);
          finalPaidForMemoryUpdate = paid;
        }

        values.add([
          rowId,
          (data['productId'] ?? [])[i]?.toString() ?? '',
          (data['productName'] ?? [])[i]?.toString() ?? '',
          (data['quantity'] ?? [])[i]?.toString() ?? '0',
          (data['purchasePrice'] ?? [])[i]?.toString() ?? '0',
          total.toString(),
          (data['supplier'] ?? [])[i]?.toString() ?? '',
          (data['date'] ?? [])[i]?.toString() ?? '',
          (data['time'] ?? [])[i]?.toString() ?? '',
          (data['isCredit'] ?? [])[i]?.toString() ?? 'false',
          paid.toString(),
        ]);
      }

      await _sheets.writeToSheet(sheetName: 'Purchases', values: values);

      // Keep the in-memory list (and the Purchase screen) in sync immediately
      if (finalPaidForMemoryUpdate != null) {
        final index = purchases.indexWhere((p) => p.id == purchaseId);
        if (index != -1) {
          purchases[index] = purchases[index].copyWith(amountPaid: finalPaidForMemoryUpdate);
          applyPurchaseFilters();
        }
      }
    } catch (e) {
      print('Error applying debt payment to purchase: $e');
    }
  }
  double getTotalPurchaseCost() {
    return purchases.fold(0.0, (sum, p) => sum + p.total);
  }

  Map<String, double> getSupplierStats() {
    final stats = <String, double>{};
    for (var purchase in purchases) {
      if (purchase.supplier.isNotEmpty) {
        stats[purchase.supplier] = (stats[purchase.supplier] ?? 0) + purchase.total;
      }
    }
    return stats;
  }
}