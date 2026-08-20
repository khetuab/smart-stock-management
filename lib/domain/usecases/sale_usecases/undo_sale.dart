import '../../../data/repositories/sale_repository.dart';

class UndoSaleUseCase {
  final SaleRepository repository;

  UndoSaleUseCase(this.repository);

  Future<void> execute(String saleId) async {
    await repository.undoSale(saleId);
  }
}