import 'package:get/get.dart';
import '../services/google_sheets_service.dart';
import '../../domain/entities/product.dart';
import '../../core/utils/helpers.dart';

class ProductRepository {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  Future<List<ProductEntity>> getProducts() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Products');
      final products = <ProductEntity>[];

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
        products.add(ProductEntity(
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
      print('Error getting products: $e');
      return [];
    }
  }

  Future<void> addProduct(ProductEntity product) async {
    try {
      await _sheets.appendToSheet(
        sheetName: 'Products',
        rowData: [
          Helpers.generateId(),
          product.name,
          product.category,
          product.image,
          product.purchasePrice,
          product.sellingPrice,
          product.quantity,
          product.minQuantity,
          product.barcode,
          product.description,
          DateTime.now().toIso8601String(),
        ],
      );
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(ProductEntity product) async {
    // Implementation similar to controller
  }

  Future<void> deleteProduct(String productId) async {
    // Implementation similar to controller
  }
}