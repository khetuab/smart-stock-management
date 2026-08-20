import '../../entities/product.dart';
import '../../../data/repositories/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  Future<void> execute(ProductEntity product) async {
    await repository.updateProduct(product);
  }
}