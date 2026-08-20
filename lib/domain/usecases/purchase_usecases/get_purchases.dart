import '../../entities/purchase.dart';
import '../../../data/repositories/purchase_repository.dart';

class GetPurchasesUseCase {
  final PurchaseRepository repository;

  GetPurchasesUseCase(this.repository);

  Future<List<PurchaseEntity>> execute() async {
    return await repository.getPurchases();
  }
}