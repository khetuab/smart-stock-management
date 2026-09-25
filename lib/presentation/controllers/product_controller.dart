import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/models/product_model.dart';
import '../../core/utils/helpers.dart';

class ProductController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();
  final CloudinaryService _cloudinary = CloudinaryService();

  // Standard Headers for Products Sheet
  static const List<String> productHeaders = [
    'id',
    'name',
    'category',
    'image',
    'purchasePrice',
    'sellingPrice',
    'quantity',
    'minQuantity',
    'barcode',
    'description',
    'dateAdded'
  ];

  // List of products
  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var isLoading = false.obs;
  var isSearching = false.obs;
  var searchQuery = ''.obs;

  // Filter
  var selectedCategory = 'All'.obs;
  var categories = <String>[].obs;

  // Product form
  var isEditing = false.obs;
  var selectedProduct = Rxn<Product>();

  // Form fields
  var productName = ''.obs;
  var productCategory = ''.obs;
  var productImage = ''.obs;
  var purchasePrice = 0.0.obs;
  var sellingPrice = 0.0.obs;
  var quantity = 0.0.obs;
  var minQuantity = 0.0.obs;
  var barcode = ''.obs;
  var description = ''.obs;

  // Form validation
  var nameError = ''.obs;
  var categoryError = ''.obs;
  var purchasePriceError = ''.obs;
  var sellingPriceError = ''.obs;
  var quantityError = ''.obs;
  var minQuantityError = ''.obs;

  // in product_controller.dart
  static ProductController get to {
    if (Get.isRegistered<ProductController>()) return Get.find<ProductController>();
    return Get.put(ProductController(), permanent: true);
  }
  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    int retries = 3;
    while (retries > 0) {
      try {
        isLoading.value = true;
        await _sheets.init();

        final data = await _sheets.getSheetDataWithHeaders('Products');
        final loadedProducts = _parseProducts(data);
        products.assignAll(loadedProducts);

        _updateCategories();
        applyFilters();
        break;
      } catch (e) {
        retries--;
        print('❌ [PRODUCT] Error loading products ($retries retries left): $e');
        if (retries == 0) {
          Get.snackbar(
              'Connection Error',
              'Failed to load products from Google Sheets.',
              colorText: Colors.red,
              snackPosition: SnackPosition.BOTTOM
          );
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      } finally {
        isLoading.value = false;
      }
    }
  }

  void _updateCategories() {
    final uniqueCategories = products
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    uniqueCategories.sort();
    categories.assignAll(['All', ...uniqueCategories]);
    print('📊 [PRODUCT] Updated categories: $categories');
  }

  List<Product> _parseProducts(Map<String, List<dynamic>> data) {
    final parsed = <Product>[];
    if (data.isEmpty) return parsed;

    List<dynamic> getCol(String target) {
      final targetClean = target.replaceAll(RegExp(r'[\s_]'), '').toLowerCase();
      for (var entry in data.entries) {
        final keyClean = entry.key.replaceAll(RegExp(r'[\s_]'), '').toLowerCase();
        if (keyClean == targetClean) {
          return entry.value;
        }
      }
      return [];
    }

    final ids = getCol('id');
    final names = getCol('name');
    final categories = getCol('category');
    final images = getCol('image');
    final purchasePrices = getCol('purchasePrice');
    final sellingPrices = getCol('sellingPrice');
    final quantities = getCol('quantity');
    final minQuantities = getCol('minQuantity');
    final barcodes = getCol('barcode');
    final descriptions = getCol('description');
    final dates = getCol('dateAdded');

    final totalRows = [
      names.length,
      ids.length,
      categories.length,
      quantities.length
    ].reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < totalRows; i++) {
      final rawName = i < names.length ? names[i]?.toString().trim() ?? '' : '';
      if (rawName.isEmpty || rawName.toLowerCase() == 'name') continue;

      String category = 'General';
      if (i < categories.length && categories[i] != null) {
        final catValue = categories[i].toString().trim();
        if (catValue.isNotEmpty) {
          category = catValue;
        }
      }

      final product = Product(
        id: i < ids.length ? ids[i]?.toString().trim() ?? '' : Helpers.generateId(),
        name: rawName,
        category: category,
        image: i < images.length ? images[i]?.toString().trim() ?? '' : '',
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
        barcode: i < barcodes.length ? barcodes[i]?.toString().trim() ?? '' : '',
        description: i < descriptions.length ? descriptions[i]?.toString().trim() ?? '' : '',
        dateAdded: i < dates.length ? dates[i]?.toString().trim() ?? '' : DateTime.now().toIso8601String(),
      );

      parsed.add(product);
    }

    return parsed;
  }

  void applyFilters() {
    var filtered = List<Product>.from(products);

    if (selectedCategory.value != 'All') {
      filtered = filtered
          .where((p) => p.category.trim().toLowerCase() == selectedCategory.value.trim().toLowerCase())
          .toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      filtered = filtered.where((p) =>
      p.name.toLowerCase().contains(query) ||
          p.barcode.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query)
      ).toList();
    }

    filteredProducts.assignAll(filtered);
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    applyFilters();
  }

  /// Helper to check if headers exist in sheet; writes them if empty.
  Future<void> _ensureHeadersExist() async {
    final existingData = await _sheets.getSheetDataWithHeaders('Products');
    if (existingData.isEmpty) {
      // Sheet has no header row -> write headers on row 1
      await _sheets.writeToSheet(
        sheetName: 'Products',
        values: [productHeaders],
      );
    }
  }

  Future<void> addProduct() async {
    if (!validateForm()) return;

    try {
      isLoading.value = true;
      await _sheets.init();

      await _sheets.createSheetIfNotExists('Products');
      await _ensureHeadersExist();

      final newProduct = Product(
        id: Helpers.generateId(),
        name: productName.value.trim(),
        category: productCategory.value.trim(),
        image: productImage.value.trim(),
        purchasePrice: purchasePrice.value,
        sellingPrice: sellingPrice.value,
        quantity: quantity.value,
        minQuantity: minQuantity.value,
        barcode: barcode.value.trim(),
        description: description.value.trim(),
        dateAdded: DateTime.now().toIso8601String(),
      );

      await _sheets.appendToSheet(
        sheetName: 'Products',
        rowData: [
          newProduct.id,
          newProduct.name,
          newProduct.category,
          newProduct.image,
          newProduct.purchasePrice,
          newProduct.sellingPrice,
          newProduct.quantity,
          newProduct.minQuantity,
          newProduct.barcode,
          newProduct.description,
          newProduct.dateAdded,
        ],
      );

      // Local State Update
      products.add(newProduct);
      _updateCategories();
      applyFilters(); // <-- Instantly refreshes filteredProducts .obs
      clearForm();

      if (Get.currentRoute == '/add-product') {
        Get.back(result: true);
      }

      Get.snackbar(
          'Success',
          'Product added successfully',
          colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM
      );

    } catch (e) {
      Get.snackbar(
          'Error',
          'Failed to add product: $e',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct() async {
    if (!validateForm()) return;
    if (selectedProduct.value == null) return;

    try {
      isLoading.value = true;
      await _sheets.init();

      final updatedProduct = selectedProduct.value!.copyWith(
        name: productName.value.trim(),
        category: productCategory.value.trim(),
        image: productImage.value.trim(),
        purchasePrice: purchasePrice.value,
        sellingPrice: sellingPrice.value,
        quantity: quantity.value,
        minQuantity: minQuantity.value,
        barcode: barcode.value.trim(),
        description: description.value.trim(),
      );

      final index = products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        products[index] = updatedProduct;
        await _rewriteAllProductsToSheet();

        _updateCategories();
        applyFilters(); // <-- Instantly refreshes filteredProducts .obs
        clearForm();

        if (Get.currentRoute == '/add-product') {
          Get.back(result: true);
        }

        Get.snackbar(
            'Success',
            'Product updated successfully',
            colorText: Colors.green,
            snackPosition: SnackPosition.BOTTOM
        );
      }
    } catch (e) {
      Get.snackbar(
          'Error',
          'Failed to update product: $e',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(Product product) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isLoading.value = true;
      await _sheets.init();

      // Immediate local removal
      products.removeWhere((p) => p.id == product.id);
      _updateCategories();
      applyFilters(); // <-- Instantly updates screen list without waiting for sheets write

      await _sheets.clearSheet('Products');
      await _rewriteAllProductsToSheet();

      clearForm();

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      await loadProducts(); // Re-sync if network write fails
      Get.snackbar(
          'Error',
          'Failed to delete product: $e',
          colorText: Colors.red,
          snackPosition: SnackPosition.BOTTOM
      );
    } finally {
      isLoading.value = false;
    }
  }

  Product? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Reduces [productId]'s stock by [amount] and persists just that one
  /// row (via [GoogleSheetsService.findRowIndexById] + `updateRow`)
  /// instead of rewriting the whole Products sheet.
  ///
  /// Throws if the product can't be found or doesn't have enough stock,
  /// so a caller (order approval) can show a clear message instead of
  /// silently letting stock go negative. If the local quantity update
  /// succeeds but the sheet write fails, the local change is rolled back
  /// so the UI never shows stock that wasn't actually saved.
  Future<void> reduceStock(String productId, double amount) async {
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      throw Exception('Product not found.');
    }

    final original = products[index];
    if (original.quantity < amount) {
      throw Exception(
        'Not enough stock for "${original.name}" (have ${original.quantity}, need $amount).',
      );
    }

    final updated = original.copyWith(quantity: original.quantity - amount);
    products[index] = updated;
    applyFilters();

    try {
      await _sheets.init();
      final rowIndex = await _sheets.findRowIndexById(
        sheetName: 'Products',
        idColumn: 'id',
        id: productId,
      );

      if (rowIndex != null) {
        await _sheets.updateRow(
          sheetName: 'Products',
          rowIndex: rowIndex,
          rowData: [
            updated.id,
            updated.name,
            updated.category,
            updated.image,
            updated.purchasePrice,
            updated.sellingPrice,
            updated.quantity,
            updated.minQuantity,
            updated.barcode,
            updated.description,
            updated.dateAdded,
          ],
        );
      } else {
        // Couldn't locate the row by id (e.g. older data) — fall back to
        // a full rewrite rather than silently failing to persist.
        await _rewriteAllProductsToSheet();
      }
    } catch (e) {
      products[index] = original;
      applyFilters();
      rethrow;
    }
  }

  Future<void> _rewriteAllProductsToSheet() async {
    // Always include productHeaders as row 1
    final List<List<dynamic>> values = [productHeaders];

    for (var p in products) {
      values.add([
        p.id,
        p.name,
        p.category,
        p.image,
        p.purchasePrice,
        p.sellingPrice,
        p.quantity,
        p.minQuantity,
        p.barcode,
        p.description,
        p.dateAdded,
      ]);
    }

    await _sheets.writeToSheet(
      sheetName: 'Products',
      values: values,
    );
  }

  bool validateForm() {
    bool isValid = true;

    if (productName.value.trim().isEmpty) {
      nameError.value = 'Please enter product name';
      isValid = false;
    } else {
      nameError.value = '';
    }

    if (productCategory.value.trim().isEmpty) {
      categoryError.value = 'Please select a category';
      isValid = false;
    } else {
      categoryError.value = '';
    }

    if (purchasePrice.value <= 0) {
      purchasePriceError.value = 'Please enter purchase price';
      isValid = false;
    } else {
      purchasePriceError.value = '';
    }

    if (sellingPrice.value <= 0) {
      sellingPriceError.value = 'Please enter selling price';
      isValid = false;
    } else {
      sellingPriceError.value = '';
    }

    if (quantity.value < 0) {
      quantityError.value = 'Please enter quantity';
      isValid = false;
    } else {
      quantityError.value = '';
    }

    if (minQuantity.value < 0) {
      minQuantityError.value = 'Please enter minimum quantity';
      isValid = false;
    } else {
      minQuantityError.value = '';
    }

    return isValid;
  }

  void editProduct(Product product) {
    isEditing.value = true;
    selectedProduct.value = product;
    productName.value = product.name;
    productCategory.value = product.category;
    productImage.value = product.image;
    purchasePrice.value = product.purchasePrice;
    sellingPrice.value = product.sellingPrice;
    quantity.value = product.quantity;
    minQuantity.value = product.minQuantity;
    barcode.value = product.barcode;
    description.value = product.description;
  }

  void clearForm() {
    isEditing.value = false;
    selectedProduct.value = null;
    productName.value = '';
    productCategory.value = '';
    productImage.value = '';
    purchasePrice.value = 0.0;
    sellingPrice.value = 0.0;
    quantity.value = 0.0;
    minQuantity.value = 0.0;
    barcode.value = '';
    description.value = '';
    nameError.value = '';
    categoryError.value = '';
    purchasePriceError.value = '';
    sellingPriceError.value = '';
    quantityError.value = '';
    minQuantityError.value = '';
  }

  void setImage(String url) {
    productImage.value = url;
  }

  List<Product> getProductsByCategory(String categoryName) {
    return products.where((p) =>
    p.category.trim().toLowerCase() == categoryName.trim().toLowerCase()
    ).toList();
  }
}