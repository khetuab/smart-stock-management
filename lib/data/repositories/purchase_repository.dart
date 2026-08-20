import '../services/google_sheets_service.dart';
import '../../domain/entities/purchase.dart';

class PurchaseRepository {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  Future<List<PurchaseEntity>> getPurchases() async {
    // Implementation similar to sales
    return [];
  }

  Future<void> createPurchase(PurchaseEntity purchase) async {
    // Implementation
  }
}