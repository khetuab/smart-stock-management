import '../services/google_sheets_service.dart';
import '../../domain/entities/sale.dart';

class SaleRepository {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  Future<List<SaleEntity>> getSales() async {
    try {
      final data = await _sheets.getSheetDataWithHeaders('Sales');
      final sales = <SaleEntity>[];

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
        sales.add(SaleEntity(
          id: ids[i]?.toString() ?? '',
          productId: i < productIds.length ? productIds[i]?.toString() ?? '' : '',
          productName: i < productNames.length ? productNames[i]?.toString() ?? '' : '',
          quantity: i < quantities.length
              ? double.tryParse(quantities[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          sellingPrice: i < sellingPrices.length
              ? double.tryParse(sellingPrices[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          total: i < totals.length
              ? double.tryParse(totals[i]?.toString() ?? '0') ?? 0.0
              : 0.0,
          date: i < dates.length ? dates[i]?.toString() ?? '' : '',
          time: i < times.length ? times[i]?.toString() ?? '' : '',
          status: i < statuses.length ? statuses[i]?.toString() ?? 'completed' : 'completed',
        ));
      }

      return sales;
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  Future<void> createSale(SaleEntity sale) async {
    // Implementation
  }

  Future<void> undoSale(String saleId) async {
    // Implementation
  }
}