import '../../entities/sale.dart';
import '../../../data/repositories/sale_repository.dart';

class GetSalesUseCase {
  final SaleRepository repository;

  GetSalesUseCase(this.repository);

  Future<List<SaleEntity>> execute() async {
    return await repository.getSales();
  }
}