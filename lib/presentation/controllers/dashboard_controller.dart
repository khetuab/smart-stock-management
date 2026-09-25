import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/zakat_controller.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/purchase_model.dart';
import 'auth_controller.dart';
import 'debt_controller.dart';

class DashboardController extends GetxController {
  final SharedPreferencesService _prefs = SharedPreferencesService();
  final GoogleSheetsService _sheets = GoogleSheetsService();

  var isLoading = true.obs;
  var totalProducts = 0.obs;
  var inventoryValue = 0.0.obs;
  var todaySales = 0.0.obs;
  var weeklySales = 0.0.obs;
  var monthlySales = 0.0.obs;
  var lowStockCount = 0.obs;
  var recentSales = <Sale>[].obs;
  var recentPurchases = <Purchase>[].obs;
  var lowStockProducts = <Product>[].obs;
  var zakatEnabled = false.obs;

  var storeName = ''.obs;
  var storeLogo = ''.obs;
  var themeColor = '#2196F3'.obs;
  var currency = 'ETB'.obs;

  @override
  void onInit() {
    super.onInit();
    loadStoreInfo();

    // Customers never see Sales/Purchases/Low-stock analytics — pulling
    // that data for every customer session wastes a Google Sheets round
    // trip (and API quota) on data they'll never use. Only fetch it for
    // the admin.
    if (AuthController.to.isAdmin) {
      loadDashboardData();
    } else {
      isLoading.value = false;
    }
  }

  double get totalReceivables => DebtController.to.totalReceivables;
  double get totalPayables => DebtController.to.totalPayables;

  /// Populates store branding (name/logo/currency/theme color/zakat).
  ///
  /// Previously this only read from local SharedPreferences — which is
  /// ONLY ever populated by the Setup wizard. Any device that never ran
  /// Setup (every customer device, or an admin session that just logs
  /// back in on a fresh install) had nothing cached locally, so these
  /// values silently stayed at their hardcoded fallback forever, no
  /// matter what was actually saved in the 'StoreInfo' Google Sheet.
  ///
  /// Fix: show the local cache immediately (fast, works offline), then
  /// fetch the 'StoreInfo' sheet — the real source of truth — and
  /// refresh both the in-memory values AND the local cache from it.
  Future<void> loadStoreInfo() async {
    // Fast path — whatever's cached locally, shown immediately so the
    // UI isn't blank while the network call below is in flight.
    storeName.value = _prefs.getString('storeName') ?? 'Smart Stock';
    storeLogo.value = _prefs.getString('storeLogo') ?? '';
    themeColor.value = _prefs.getString('themeColor') ?? '#2196F3';
    currency.value = _prefs.getString('currency') ?? 'ETB';
    zakatEnabled.value = _prefs.isZakatEnabled();

    try {
      await _sheets.init();
      final data = await _sheets.getSheetDataWithHeaders('StoreInfo');
      if (data.isEmpty) return;

      dynamic firstOf(String key) {
        final col = data[key];
        if (col == null || col.isEmpty) return null;
        return col.first;
      }

      final sheetStoreName = firstOf('Store Name')?.toString().trim();
      final sheetStoreLogo = firstOf('Store Logo')?.toString().trim();
      final sheetCurrency = firstOf('Currency')?.toString().trim();
      final sheetThemeColor = firstOf('Theme Color')?.toString().trim();
      final sheetZakat = firstOf('Zakat Enabled')?.toString().trim().toLowerCase();

      if (sheetStoreName != null && sheetStoreName.isNotEmpty) {
        storeName.value = sheetStoreName;
        await _prefs.setString('storeName', sheetStoreName);
      }
      if (sheetStoreLogo != null && sheetStoreLogo.isNotEmpty) {
        storeLogo.value = sheetStoreLogo;
        await _prefs.setString('storeLogo', sheetStoreLogo);
      }
      if (sheetCurrency != null && sheetCurrency.isNotEmpty) {
        currency.value = sheetCurrency;
        await _prefs.setString('currency', sheetCurrency);
      }
      if (sheetThemeColor != null && sheetThemeColor.isNotEmpty) {
        themeColor.value = sheetThemeColor;
        await _prefs.setString('themeColor', sheetThemeColor);
      }
      if (sheetZakat != null) {
        zakatEnabled.value = sheetZakat == 'true';
      }
    } catch (e) {
      print('Error loading StoreInfo sheet: $e');
      // Keep whatever the local-cache fast path already set above.
    }
  }

  /// Parse dates with multiple formats including Google Sheets serial dates
  DateTime? _parseFlexibleDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;

    final cleanStr = dateStr.trim().split(' ').first;

    // Handle Google Sheets numeric serial dates (e.g., "46227")
    final numericDate = int.tryParse(cleanStr);
    if (numericDate != null) {
      // Google Sheets date serial: days since December 30, 1899
      final parsedDate = DateTime(1899, 12, 30).add(Duration(days: numericDate));
      return parsedDate;
    }

    // Try standard ISO format
    try {
      return DateTime.parse(cleanStr);
    } catch (_) {
      // Try custom formats
      try {
        final delimiter = cleanStr.contains('/') ? '/' : '-';
        final parts = cleanStr.split(delimiter);

        if (parts.length == 3) {
          int year, month, day;

          if (parts[0].length == 4) {
            // YYYY/MM/DD
            year = int.parse(parts[0]);
            month = int.parse(parts[1]);
            day = int.parse(parts[2]);
          } else if (parts[2].length == 4) {
            // DD/MM/YYYY or MM/DD/YYYY
            year = int.parse(parts[2]);
            // Assume DD/MM/YYYY (most common in Ethiopia)
            day = int.parse(parts[0]);
            month = int.parse(parts[1]);
          } else {
            return null;
          }

          return DateTime(year, month, day);
        }
      } catch (e) {
        print('Could not parse date: "$dateStr"');
      }
    }
    return null;
  }

  /// Sort sales by date (newest first)
  List<Sale> _sortSalesByDate(List<Sale> sales) {
    return List<Sale>.from(sales)..sort((a, b) {
      final dateA = _parseFlexibleDate(a.date) ?? DateTime(1970);
      final dateB = _parseFlexibleDate(b.date) ?? DateTime(1970);

      if (dateA == dateB) {
        final timeA = a.time.isNotEmpty ? a.time : '00:00:00';
        final timeB = b.time.isNotEmpty ? b.time : '00:00:00';
        return timeB.compareTo(timeA);
      }

      return dateB.compareTo(dateA);
    });
  }

  /// Sort purchases by date (newest first)
  List<Purchase> _sortPurchasesByDate(List<Purchase> purchases) {
    return List<Purchase>.from(purchases)..sort((a, b) {
      final dateA = _parseFlexibleDate(a.date) ?? DateTime(1970);
      final dateB = _parseFlexibleDate(b.date) ?? DateTime(1970);

      if (dateA == dateB) {
        final timeA = a.time.isNotEmpty ? a.time : '00:00:00';
        final timeB = b.time.isNotEmpty ? b.time : '00:00:00';
        return timeB.compareTo(timeA);
      }

      return dateB.compareTo(dateA);
    });
  }

  /// Get the "today" date normalized to midnight
  DateTime _getToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get the start of the week (Monday)
  DateTime _getWeekStart(DateTime today) {
    final daysFromMonday = today.weekday - 1;
    return today.subtract(Duration(days: daysFromMonday));
  }

  /// Check if a sale date matches the given target date
  bool _isSameDay(DateTime? saleDate, DateTime targetDate) {
    if (saleDate == null) return false;
    final saleDay = DateTime(saleDate.year, saleDate.month, saleDate.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return saleDay.isAtSameMomentAs(targetDay);
  }

  /// Check if a sale date is within the week (Monday to today)
  bool _isWithinWeek(DateTime? saleDate, DateTime weekStart, DateTime today) {
    if (saleDate == null) return false;
    final saleDay = DateTime(saleDate.year, saleDate.month, saleDate.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return saleDay.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
        saleDay.isBefore(todayEnd.add(const Duration(seconds: 1)));
  }

  /// Check if a sale date is within the current month
  bool _isWithinMonth(DateTime? saleDate, DateTime now) {
    if (saleDate == null) return false;
    return saleDate.year == now.year && saleDate.month == now.month;
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      await _sheets.init();

      final products = await _loadProducts();

      totalProducts.value = products.fold<int>(
        0,
            (sum, product) => sum + product.quantity.toInt(),
      );

      inventoryValue.value = products.fold(0.0, (sum, product) {
        return sum + (product.purchasePrice * product.quantity);
      });

      final sales = await _loadSales();

      final today = _getToday();
      final weekStart = _getWeekStart(today);

      todaySales.value = sales.where((s) {
        final parsed = _parseFlexibleDate(s.date);
        return _isSameDay(parsed, today);
      }).fold(0.0, (sum, sale) => sum + sale.total);

      weeklySales.value = sales.where((s) {
        final parsed = _parseFlexibleDate(s.date);
        return _isWithinWeek(parsed, weekStart, today);
      }).fold(0.0, (sum, sale) => sum + sale.total);

      monthlySales.value = sales.where((s) {
        final parsed = _parseFlexibleDate(s.date);
        return _isWithinMonth(parsed, DateTime.now());
      }).fold(0.0, (sum, sale) => sum + sale.total);

      final sortedSales = _sortSalesByDate(sales);
      recentSales.value = sortedSales.take(5).toList();

      lowStockProducts.value = products.where((p) => p.quantity <= p.minQuantity).toList();
      lowStockCount.value = lowStockProducts.length;

      final purchases = await _loadPurchases();
      final sortedPurchases = _sortPurchasesByDate(purchases);
      recentPurchases.value = sortedPurchases.take(5).toList();

    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> _loadProducts() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Products');
      if (data.isEmpty) return [];

      final products = <Product>[];
      final names = data['name'] ?? [];
      final categories = data['category'] ?? [];
      final images = data['image'] ?? [];
      final purchasePrices = data['purchasePrice'] ?? [];
      final sellingPrices = data['sellingPrice'] ?? [];
      final quantities = data['quantity'] ?? [];
      final minQuantities = data['minQuantity'] ?? [];
      final barcodes = data['barcode'] ?? [];
      final descriptions = data['description'] ?? [];
      final ids = data['id'] ?? [];
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
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  Future<List<Sale>> _loadSales() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Sales');
      if (data.isEmpty) return [];

      final sales = <Sale>[];
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
        final status = i < statuses.length ? statuses[i]?.toString() ?? 'completed' : 'completed';
        if (status == 'cancelled') continue;

        final rawDate = i < dates.length ? dates[i]?.toString() ?? '' : '';
        final rawTotal = i < totals.length ? totals[i]?.toString() ?? '0' : '0';

        sales.add(Sale(
          id: ids[i]?.toString() ?? '',
          productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
          productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
          quantity: i < quantities.length ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0 : 0.0,
          sellingPrice: i < sellingPrices.length ? double.tryParse(sellingPrices[i]?.toString() ?? '0') ?? 0.0 : 0.0,
          total: double.tryParse(rawTotal.replaceAll(',', '')) ?? 0.0,
          date: rawDate,
          time: i < times.length ? times[i]?.toString() ?? '' : '',
          status: status,
        ));
      }

      return sales;
    } catch (e) {
      print('Error loading sales: $e');
      return [];
    }
  }

  Future<List<Purchase>> _loadPurchases() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Purchases');
      if (data.isEmpty) return [];

      final purchases = <Purchase>[];
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
          total: i < totals.length
              ? double.tryParse(totals[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          supplier: i < suppliers.length ? suppliers[i]?.toString() ?? '' : '',
          date: i < dates.length ? dates[i]?.toString() ?? '' : '',
          time: i < times.length ? times[i]?.toString() ?? '' : '',
        ));
      }

      return purchases;
    } catch (e) {
      print('Error loading purchases: $e');
      return [];
    }
  }

  Future<void> refreshDashboard() async {
    await loadStoreInfo();

    if (Get.isRegistered<ZakatController>()) {
      Get.find<ZakatController>().refreshZakatData();
    }

    if (AuthController.to.isAdmin) {
      await loadDashboardData();
    }
  }

  String formatCurrency(double amount) {
    final currencySymbol = currency.value == 'ETB' ? 'Br' :
    currency.value == 'USD' ? '\$' : '€';
    return '$currencySymbol ${amount.toStringAsFixed(2)}';
  }
}