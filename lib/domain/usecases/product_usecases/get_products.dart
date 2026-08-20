import '../../entities/product.dart';
import '../../../data/repositories/product_repository.dart';

class GetProductsUseCase {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  Future<List<ProductEntity>> execute() async {
    return await repository.getProducts();
  }
}