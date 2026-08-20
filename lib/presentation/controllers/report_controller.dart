import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/product_controller.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/purchase_model.dart';
import '../../data/models/product_model.dart';

class ReportController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  var isLoading = false.obs;
  var selectedReportType = 'Daily'.obs;

  // Report data
  var totalSales = 0.0.obs;
  var totalPurchases = 0.0.obs;
  var estimatedProfit = 0.0.obs;
  var bestSellingProducts = <Map<String, dynamic>>[].obs;
  var lowStockProducts = <Product>[].obs;

  // Chart data
  var dailySalesData = <ChartData>[].obs;
  var categorySalesData = <ChartData>[].obs;

  var reportStartDate = Rxn<DateTime>();
  var reportEndDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    // Default to start of current month normalized to 00:00:00
    reportStartDate.value = DateTime(now.year, now.month, 1);
    reportEndDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
    generateReport();
  }

  /// Helper to safely parse dates, string formats, and Google Sheets numeric serial dates (e.g. "46227")
  DateTime? _parseFlexibleDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    final cleanStr = dateStr.trim().split(' ').first;

    // Handle Google Sheets numeric serial dates
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
            final p1 = int.parse(parts[0]);
            final p2 = int.parse(parts[1]);

            if (p1 > 12) {
              day = p1;
              month = p2;
            } else {
              day = p1;
              month = p2;
            }
          } else {
            return null;
          }

          return DateTime(year, month, day);
        }
      } catch (e) {
        print('Error parsing date in report: $dateStr');
      }
    }
    return null;
  }

  Future<void> generateReport() async {
    try {
      isLoading.value = true;
      await _sheets.init();

      // Load data
      final salesData = await _sheets.getSheetDataWithHeaders('Sales');
      final purchaseData = await _sheets.getSheetDataWithHeaders('Purchases');
      final productData = await _sheets.getSheetDataWithHeaders('Products');

      final sales = _parseSales(salesData);
      final purchases = _parsePurchases(purchaseData);
      final products = _parseProducts(productData);

      // Filter by date range
      final filteredSales = _filterSalesByDate(sales);
      final filteredPurchases = _filterPurchasesByDate(purchases);

      // Calculate totals
      totalSales.value = filteredSales.fold(0.0, (sum, s) => sum + s.total);
      totalPurchases.value = filteredPurchases.fold(0.0, (sum, p) => sum + p.total);
      estimatedProfit.value = totalSales.value - totalPurchases.value;

      // Find best selling products
      final productSales = <String, Map<String, dynamic>>{};
      for (var sale in filteredSales) {
        if (!productSales.containsKey(sale.productId)) {
          productSales[sale.productId] = {
            'name': sale.productName,
            'quantity': 0.0,
            'revenue': 0.0,
          };
        }
        productSales[sale.productId]!['quantity'] =
            (productSales[sale.productId]!['quantity'] as double) + sale.quantity;
        productSales[sale.productId]!['revenue'] =
            (productSales[sale.productId]!['revenue'] as double) + sale.total;
      }

      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['quantity'] as double).compareTo(a['quantity'] as double));
      bestSellingProducts.value = sortedProducts.take(5).toList();

      // Find low stock products
      lowStockProducts.value = products.where((p) => p.quantity <= p.minQuantity).toList();

      // Prepare chart data
      _prepareChartData(filteredSales);

    } catch (e) {
      print('Error generating report: $e');
      Get.snackbar(
        'Error',
        'Failed to generate report: $e',
        colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
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

    for (int i = 0; i < ids.length; i++) {
      if (i < statuses.length && statuses[i]?.toString() == 'cancelled') continue;

      final rawTotal = i < totals.length ? totals[i]?.toString() ?? '0' : '0';

      sales.add(Sale(
        id: ids[i]?.toString() ?? '',
        productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
        productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
        quantity: i < quantities.length
            ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0
            : 0.0,
        sellingPrice: i < sellingPrices.length
            ? double.tryParse(sellingPrices[i]?.toString() ?? '0') ?? 0.0
            : 0.0,
        total: double.tryParse(rawTotal.replaceAll(',', '')) ?? 0.0,
        date: i < dates.length ? dates[i]?.toString() ?? '' : '',
        time: i < times.length ? times[i]?.toString() ?? '' : '',
        status: i < statuses.length ? statuses[i]?.toString() ?? 'completed' : 'completed',
      ));
    }

    return sales;
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

    for (int i = 0; i < ids.length; i++) {
      final rawTotal = i < totals.length ? totals[i]?.toString() ?? '0' : '0';

      purchases.add(Purchase(
        id: ids[i]?.toString() ?? '',
        productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
        productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
        quantity: i < quantities.length
            ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0
            : 0.0,
        purchasePrice: i < purchasePrices.length
            ? double.tryParse(purchasePrices[i]?.toString() ?? '0') ?? 0.0
            : 0.0,
        total: double.tryParse(rawTotal.replaceAll(',', '')) ?? 0.0,
        supplier: i < suppliers.length ? suppliers[i]?.toString() ?? '' : '',
        date: i < dates.length ? dates[i]?.toString() ?? '' : '',
        time: i < times.length ? times[i]?.toString() ?? '' : '',
      ));
    }

    return purchases;
  }

  List<Product> _parseProducts(Map<String, List<dynamic>> data) {
    final products = <Product>[];
    if (data.isEmpty) return products;

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
      products.add(Product(
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
      ));
    }

    return products;
  }

  List<Sale> _filterSalesByDate(List<Sale> sales) {
    if (reportStartDate.value == null || reportEndDate.value == null) {
      return sales;
    }

    final start = DateTime(
      reportStartDate.value!.year,
      reportStartDate.value!.month,
      reportStartDate.value!.day,
    );
    final end = DateTime(
      reportEndDate.value!.year,
      reportEndDate.value!.month,
      reportEndDate.value!.day,
      23, 59, 59,
    );

    return sales.where((s) {
      final parsedDate = _parseFlexibleDate(s.date);
      if (parsedDate == null) return false;

      final normalizedSaleDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      return !normalizedSaleDate.isBefore(start) && !normalizedSaleDate.isAfter(end);
    }).toList();
  }

  List<Purchase> _filterPurchasesByDate(List<Purchase> purchases) {
    if (reportStartDate.value == null || reportEndDate.value == null) {
      return purchases;
    }

    final start = DateTime(
      reportStartDate.value!.year,
      reportStartDate.value!.month,
      reportStartDate.value!.day,
    );
    final end = DateTime(
      reportEndDate.value!.year,
      reportEndDate.value!.month,
      reportEndDate.value!.day,
      23, 59, 59,
    );

    return purchases.where((p) {
      final parsedDate = _parseFlexibleDate(p.date);
      if (parsedDate == null) return false;

      final normalizedPurchaseDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      return !normalizedPurchaseDate.isBefore(start) && !normalizedPurchaseDate.isAfter(end);
    }).toList();
  }

  void _prepareChartData(List<Sale> sales) {
    // Daily sales data
    final dailyMap = <String, double>{};
    for (var sale in sales) {
      final parsedDate = _parseFlexibleDate(sale.date);
      if (parsedDate != null) {
        final formattedLabel =
            '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
        dailyMap[formattedLabel] = (dailyMap[formattedLabel] ?? 0) + sale.total;
      }
    }

    final sortedDates = dailyMap.keys.toList()..sort();
    dailySalesData.value = sortedDates.map((dateKey) {
      // Short label for chart x-axis (e.g. "07/24")
      final parts = dateKey.split('-');
      final shortLabel = parts.length == 3 ? '${parts[1]}/${parts[2]}' : dateKey;
      return ChartData(shortLabel, dailyMap[dateKey] ?? 0);
    }).toList();

    // Category sales data
    final categoryMap = <String, double>{};
    for (var sale in sales) {
      final product = Get.find<ProductController>().products
          .firstWhereOrNull((p) => p.id == sale.productId);
      final category = product?.category ?? 'Uncategorized';
      categoryMap[category] = (categoryMap[category] ?? 0) + sale.total;
    }

    categorySalesData.value = categoryMap.entries.map((entry) {
      return ChartData(entry.key, entry.value);
    }).toList();
  }

  void setReportType(String type) {
    selectedReportType.value = type;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (type) {
      case 'Daily':
        reportStartDate.value = today;
        reportEndDate.value = today;
        break;
      case 'Weekly':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        reportStartDate.value = weekStart;
        reportEndDate.value = today;
        break;
      case 'Monthly':
        reportStartDate.value = DateTime(now.year, now.month, 1);
        reportEndDate.value = today;
        break;
      case 'Custom':
        break;
    }

    generateReport();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    reportStartDate.value = start;
    reportEndDate.value = end;
    generateReport();
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}