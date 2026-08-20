import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../core/utils/helpers.dart';
import 'debt_controller.dart';
import 'product_controller.dart';
import 'dashboard_controller.dart';

class SaleController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final ProductController _productController = Get.find<ProductController>();
  final DashboardController _dashboardController = Get.find<DashboardController>();

  // Cart
  var cartItems = <Map<String, dynamic>>[].obs;
  var totalAmount = 0.0.obs;

  // Sale history
  var sales = <Sale>[].obs;
  var filteredSales = <Sale>[].obs;
  var isLoading = false.obs;

  // Selected product for sale
  var selectedProduct = Rxn<Product>();
  var saleQuantity = 1.0.obs;

  // Filter
  var selectedFilter = 'Today'.obs;
  var customStartDate = Rxn<DateTime>();
  var customEndDate = Rxn<DateTime>();

  // --- Credit sale fields ---
  var isCreditSale = false.obs;
  var customerName = ''.obs;
  var customerPhone = ''.obs;

  // Store the last completed sale for undo
  Sale? _lastCompletedSale;
  List<Map<String, dynamic>> _lastSaleItems = [];

  static SaleController get to {
    if (Get.isRegistered<SaleController>()) return Get.find<SaleController>();
    return Get.put(SaleController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      isLoading.value = true;
      await _sheets.init();

      final data = await _sheets.getSheetDataWithHeaders('Sales');
      sales.value = _parseSales(data);
      applySaleFilters();
    } catch (e) {
      print('Error loading sales: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Sale> _parseSales(Map<String, List<dynamic>> data) {
    final sales = <Sale>[];
    if (data.isEmpty) return sales;

    final ids = data['id'] ?? [];
    final productIds = data['productId'] ?? [];
    final productNames = data['productName'] ?? [];
    final quantities = data['quantity'] ?? [];
    final sellingPrices = data['sellingPrice'] ?? [];
    final totals = data['total'] ?? [];
    final dates = data['date'] ?? [];
    final times = data['time'] ?? [];
    final statuses = data['status'] ?? [];
    final isCredits = data['isCredit'] ?? [];
    final customerNames = data['customerName'] ?? [];
    final customerPhones = data['customerPhone'] ?? [];
    final amountPaids = data['amountPaid'] ?? [];

    for (int i = 0; i < ids.length; i++) {
      final status = i < statuses.length ? statuses[i]?.toString() ?? 'completed' : 'completed';
      if (status == 'cancelled') continue;

      final total = i < totals.length ? double.tryParse(totals[i]?.toString() ?? '0') ?? 0.0 : 0.0;
      final isCredit = i < isCredits.length && (isCredits[i]?.toString().toLowerCase() == 'true');

      sales.add(Sale(
        id: ids[i]?.toString() ?? '',
        productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
        productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
        quantity: i < quantities.length ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        sellingPrice: i < sellingPrices.length ? double.tryParse(sellingPrices[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        total: total,
        date: i < dates.length ? dates[i]?.toString() ?? '' : '',
        time: i < times.length ? times[i]?.toString() ?? '' : '',
        status: status,
        isCredit: isCredit,
        customerName: i < customerNames.length ? customerNames[i]?.toString() ?? '' : '',
        customerPhone: i < customerPhones.length ? customerPhones[i]?.toString() ?? '' : '',
        amountPaid: i < amountPaids.length
            ? double.tryParse(amountPaids[i]?.toString() ?? '0') ?? (isCredit ? 0.0 : total)
            : (isCredit ? 0.0 : total),
      ));
    }
    return sales;
  }

  // Add this method to your SaleController

  void addToCartWithPrice(Product product, double quantity, double actualPrice) {
    if (quantity <= 0) {
      Get.snackbar(
        'Invalid Quantity'.tr,
        'Please enter a valid quantity'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (quantity > product.quantity) {
      Get.snackbar(
        'Not Enough Stock'.tr,
        'Only ${product.quantity} units available'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final existingIndex = cartItems.indexWhere((item) => item['productId'] == product.id);

    if (existingIndex != -1) {
      final currentQty = cartItems[existingIndex]['quantity'] as double;
      final newQty = currentQty + quantity;

      if (newQty > product.quantity) {
        Get.snackbar(
          'Not Enough Stock'.tr,
          'Only ${product.quantity} units available'.tr,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      cartItems[existingIndex]['quantity'] = newQty;
      cartItems[existingIndex]['unitPrice'] = actualPrice;
      cartItems[existingIndex]['price'] = actualPrice;
      cartItems[existingIndex]['listedPrice'] = product.sellingPrice;
      cartItems[existingIndex]['total'] = newQty * actualPrice;
    } else {
      cartItems.add({
        'productId': product.id,
        'productName': product.name,
        'product': product,
        'quantity': quantity,
        'unitPrice': actualPrice,
        'price': actualPrice,
        'listedPrice': product.sellingPrice,
        'total': quantity * actualPrice,
      });
    }

    cartItems.refresh();
    updateTotal();

    Get.snackbar(
      'Added to Cart'.tr,
      '${quantity}x ${product.name} at ${_dashboardController.formatCurrency(actualPrice)}'.tr,
      colorText: Colors.green,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  DateTime? _parseFlexibleDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    final cleanStr = dateStr.trim().split(' ').first;

    final numericDate = int.tryParse(cleanStr);
    if (numericDate != null) {
      return DateTime(1899, 12, 30).add(Duration(days: numericDate));
    }

    try {
      return DateTime.parse(cleanStr);
    } catch (_) {
      try {
        final delimiter = cleanStr.contains('/') ? '/' : '-';
        final parts = cleanStr.split(delimiter);
        if (parts.length == 3) {
          int year, month, day;
          if (parts[0].length == 4) {
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else if (parts[2].length == 4) {
            year = int.parse(parts[2]);
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
          } else {
            return null;
          }
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> applyDebtPayment(String saleId, double amount) async {
    try {
      await _sheets.init();
      final data = await _sheets.getSheetDataWithHeaders('Sales');
      if (data.isEmpty) return;

      final ids = data['id'] ?? [];
      final headers = [
        'id', 'productId', 'productName', 'quantity', 'sellingPrice', 'total',
        'date', 'time', 'status', 'isCredit', 'customerName', 'customerPhone', 'amountPaid',
      ];
      final values = <List<dynamic>>[headers];

      double? finalPaidForMemoryUpdate;

      for (int i = 0; i < ids.length; i++) {
        final rowId = ids[i]?.toString() ?? '';
        final total = double.tryParse((data['total'] ?? [])[i]?.toString() ?? '0') ?? 0.0;
        double paid = double.tryParse((data['amountPaid'] ?? [])[i]?.toString() ?? '0') ?? 0.0;

        if (rowId == saleId) {
          paid = (paid + amount).clamp(0.0, total);
          finalPaidForMemoryUpdate = paid;
        }

        values.add([
          rowId,
          (data['productId'] ?? [])[i]?.toString() ?? '',
          (data['productName'] ?? [])[i]?.toString() ?? '',
          (data['quantity'] ?? [])[i]?.toString() ?? '0',
          (data['sellingPrice'] ?? [])[i]?.toString() ?? '0',
          total.toString(),
          (data['date'] ?? [])[i]?.toString() ?? '',
          (data['time'] ?? [])[i]?.toString() ?? '',
          (data['status'] ?? [])[i]?.toString() ?? 'completed',
          (data['isCredit'] ?? [])[i]?.toString() ?? 'false',
          (data['customerName'] ?? [])[i]?.toString() ?? '',
          (data['customerPhone'] ?? [])[i]?.toString() ?? '',
          paid.toString(),
        ]);
      }

      await _sheets.writeToSheet(sheetName: 'Sales', values: values);

      if (finalPaidForMemoryUpdate != null) {
        final index = sales.indexWhere((s) => s.id == saleId);
        if (index != -1) {
          sales[index] = sales[index].copyWith(amountPaid: finalPaidForMemoryUpdate);
          applySaleFilters();
        }
      }
    } catch (e) {
      print('Error applying debt payment to sale: $e');
    }
  }

  void addToCart(Product product, double quantity) {
    // Use the product's selling price as the actual price
    addToCartWithPrice(product, quantity, product.sellingPrice);
  }

  void removeFromCart(int index) {
    cartItems.removeAt(index);
    updateTotal();
  }

  void updateCartItemPrice(int index, double newUnitPrice) {
    if (index < 0 || index >= cartItems.length || newUnitPrice < 0) return;

    final item = cartItems[index];
    final quantity = item['quantity'] as double;

    cartItems[index] = {
      ...item,
      'unitPrice': newUnitPrice,
      'price': newUnitPrice,
      'total': newUnitPrice * quantity,
    };

    cartItems.refresh();
    updateTotal();
  }

  void updateTotal() {
    totalAmount.value = cartItems.fold(
      0.0,
          (sum, item) => sum + ((item['total'] ?? 0.0) as double),
    );
  }

  void updateCartQuantity(int index, double newQuantity) {
    final item = cartItems[index];
    final product = item['product'] as Product;

    if (newQuantity <= 0) {
      removeFromCart(index);
      return;
    }

    if (newQuantity > product.quantity) {
      Get.snackbar(
          'Not Enough Stock',
          'Only ${product.quantity} units available',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    cartItems[index]['quantity'] = newQuantity;
    cartItems[index]['total'] = newQuantity * (cartItems[index]['unitPrice'] as double);
    cartItems.refresh();
    updateTotal();
  }

  Future<void> completeSale() async {
    if (cartItems.isEmpty) {
      Get.snackbar(
          'Empty Cart',
          'Please add items to the cart',
          colorText: Colors.orange,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    if (isCreditSale.value && customerName.value.trim().isEmpty) {
      Get.snackbar(
          'Customer Name Required',
          'Enter the customer\'s name for a credit sale',
          colorText: Colors.orange,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    final saleTotal = totalAmount.value;
    _lastSaleItems = List.from(cartItems);

    try {
      isLoading.value = true;
      await _sheets.init();

      final now = DateTime.now();
      final saleId = Helpers.generateId();
      final creditNow = isCreditSale.value;
      final custName = customerName.value.trim();
      final custPhone = customerPhone.value.trim();

      Product? firstProduct;
      double totalQuantity = 0;
      double totalAmountAccum = 0;

      for (var item in cartItems) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as double;
        final unitPrice = (item['unitPrice'] ?? item['price']) as double;
        final listedPrice = (item['listedPrice'] ?? product.sellingPrice) as double;
        final total = item['total'] as double;

        if (firstProduct == null) firstProduct = product;
        totalQuantity += quantity;
        totalAmountAccum += total;

        // Before appending rows in completeSale():
        final existingSalesData = await _sheets.getSheetDataWithHeaders('Sales');
        if (existingSalesData.isEmpty) {
          await _sheets.writeToSheet(
            sheetName: 'Sales',
            values: [[
              'id', 'productId', 'productName', 'quantity', 'sellingPrice',
              'total', 'date', 'time', 'status', 'isCredit', 'customerName',
              'customerPhone', 'amountPaid', 'listedPrice'
            ]],
          );
        }
        await _sheets.appendToSheet(
          sheetName: 'Sales',
          rowData: [
            saleId.toString(),
            product.id.toString(),
            product.name.toString(),
            quantity.toString(),
            unitPrice.toString(),
            total.toString(),
            now.toIso8601String().split('T')[0],
            now.toIso8601String().split('T')[1].substring(0, 8),
            'completed',
            creditNow.toString(),
            custName,
            custPhone,
            (creditNow ? 0.0 : total).toString(),
            listedPrice.toString(),
          ],
        );

        // Update product stock locally and sheet
        final updatedProduct = product.copyWith(quantity: product.quantity - quantity);
        await _updateProductQuantity(updatedProduct);
      }

      if (firstProduct != null) {
        _lastCompletedSale = Sale(
          id: saleId,
          productId: firstProduct.id,
          productName: firstProduct.name,
          quantity: totalQuantity,
          sellingPrice: firstProduct.sellingPrice,
          total: totalAmountAccum,
          date: now.toIso8601String().split('T')[0],
          time: now.toIso8601String().split('T')[1].substring(0, 8),
          status: 'completed',
          isCredit: creditNow,
          customerName: custName,
          customerPhone: custPhone,
          amountPaid: creditNow ? 0.0 : totalAmountAccum,
        );
      }

      if (creditNow) {
        final debtController = Get.find<DebtController>();
        await debtController.addDebt(
          type: 'receivable',
          refId: saleId,
          personName: custName,
          personPhone: custPhone,
          totalAmount: totalAmountAccum,
          amountPaid: 0.0,
          notes: 'Credit sale — $totalQuantity item(s)',
        );
      }

      cartItems.clear();
      totalAmount.value = 0.0;
      isCreditSale.value = false;
      customerName.value = '';
      customerPhone.value = '';

      await loadSales();
      await _productController.loadProducts();
      await _showSaleCompletedDialog(saleTotal);

    } catch (e, stackTrace) {
      print('Error completing sale: $e');
      print('Stacktrace: $stackTrace');
      Get.snackbar(
          'Error',
          'Failed to complete sale: $e',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCreditSale(bool value) => isCreditSale.value = value;
  void updateCustomerName(String value) => customerName.value = value;
  void updateCustomerPhone(String value) => customerPhone.value = value;

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

  Future<void> _showSaleCompletedDialog(double completedAmount) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sale Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${_dashboardController.formatCurrency(completedAmount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Undo',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (result == false) {
      await undoLastSale();
    }
  }

  Future<void> undoLastSale() async {
    if (_lastCompletedSale == null) {
      Get.snackbar(
          'Error',
          'No sale to undo',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    try {
      isLoading.value = true;
      await _sheets.init();

      for (var item in _lastSaleItems) {
        final product = item['product'] as Product;
        final quantity = item['quantity'] as double;

        final productIndex = _productController.products.indexWhere((p) => p.id == product.id);

        if (productIndex != -1) {
          final currentProduct = _productController.products[productIndex];
          final restoredProduct = currentProduct.copyWith(
            quantity: currentProduct.quantity + quantity,
          );

          await _updateProductQuantity(restoredProduct);
          _productController.products[productIndex] = restoredProduct;
        }
      }

      await _markSaleAsCancelled(_lastCompletedSale!.id);

      _lastCompletedSale = null;
      _lastSaleItems = [];

      await loadSales();

      Get.snackbar(
          'Undo Successful',
          'Sale has been undone',
          colorText: Colors.orange,
          snackPosition: SnackPosition.BOTTOM
      );

    } catch (e) {
      Get.snackbar(
          'Error',
          'Failed to undo sale: $e',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _markSaleAsCancelled(String saleId) async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Sales');
      if (data.isEmpty) return;

      final ids = data['id'] ?? [];
      final productIds = data['productId'] ?? [];
      final productNames = data['productName'] ?? [];
      final quantities = data['quantity'] ?? [];
      final sellingPrices = data['sellingPrice'] ?? [];
      final totals = data['total'] ?? [];
      final dates = data['date'] ?? [];
      final times = data['time'] ?? [];
      final statuses = data['status'] ?? [];

      final headers = ['id', 'productId', 'productName', 'quantity', 'sellingPrice', 'total', 'date', 'time', 'status'];
      final values = <List<dynamic>>[headers];

      for (int i = 0; i < ids.length; i++) {
        final currentId = ids[i]?.toString() ?? '';
        final status = (currentId == saleId) ? 'cancelled' : (statuses.length > i ? statuses[i]?.toString() ?? 'completed' : 'completed');

        if (status == 'cancelled') continue;

        values.add([
          currentId,
          productIds.length > i ? productIds[i]?.toString() ?? '' : '',
          productNames.length > i ? productNames[i]?.toString() ?? '' : '',
          quantities.length > i ? quantities[i]?.toString() ?? '0' : '0',
          sellingPrices.length > i ? sellingPrices[i]?.toString() ?? '0' : '0',
          totals.length > i ? totals[i]?.toString() ?? '0' : '0',
          dates.length > i ? dates[i]?.toString() ?? '' : '',
          times.length > i ? times[i]?.toString() ?? '' : '',
          status,
        ]);
      }

      await _sheets.writeToSheet(
        sheetName: 'Sales',
        values: values,
      );
    } catch (e) {
      rethrow;
    }
  }

  void applySaleFilters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<Sale> filtered = List.from(sales);

    switch (selectedFilter.value) {
      case 'Today':
        filtered = filtered.where((s) {
          final parsed = _parseFlexibleDate(s.date);
          if (parsed == null) return false;
          return DateTime(parsed.year, parsed.month, parsed.day).isAtSameMomentAs(today);
        }).toList();
        break;
      case 'This Week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        filtered = filtered.where((s) {
          final parsed = _parseFlexibleDate(s.date);
          if (parsed == null) return false;
          return parsed.isAfter(weekStart.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        filtered = filtered.where((s) {
          final parsed = _parseFlexibleDate(s.date);
          if (parsed == null) return false;
          return parsed.isAfter(monthStart.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case 'Custom':
        if (customStartDate.value != null && customEndDate.value != null) {
          filtered = filtered.where((s) {
            final date = _parseFlexibleDate(s.date);
            if (date == null) return false;
            return date.isAfter(customStartDate.value!) &&
                date.isBefore(customEndDate.value!.add(const Duration(days: 1)));
          }).toList();
        }
        break;
      default:
        final dayMap = {
          'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
          'Thursday': 4, 'Friday': 5, 'Saturday': 6, 'Sunday': 7
        };
        if (dayMap.containsKey(selectedFilter.value)) {
          final dayIndex = dayMap[selectedFilter.value]!;
          filtered = filtered.where((s) {
            final date = _parseFlexibleDate(s.date);
            if (date == null) return false;
            return date.weekday == dayIndex;
          }).toList();
        }
        break;
    }

    filteredSales.value = filtered;
  }

  void setSaleFilter(String filter) {
    selectedFilter.value = filter;
    applySaleFilters();
  }

  String formatCurrency(double amount) {
    return _dashboardController.formatCurrency(amount);
  }
}