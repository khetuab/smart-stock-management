import '../../entities/purchase.dart';
import '../../../data/repositories/purchase_repository.dart';

class CreatePurchaseUseCase {
  final PurchaseRepository repository;

  CreatePurchaseUseCase(this.repository);

  Future<void> execute(PurchaseEntity purchase) async {
    await repository.createPurchase(purchase);
  }
}