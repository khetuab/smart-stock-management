import '../../entities/sale.dart';
import '../../../data/repositories/sale_repository.dart';

class CreateSaleUseCase {
  final SaleRepository repository;

  CreateSaleUseCase(this.repository);

  Future<void> execute(SaleEntity sale) async {
    await repository.createSale(sale);
  }
}