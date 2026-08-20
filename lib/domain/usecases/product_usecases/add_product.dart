import '../../entities/product.dart';
import '../../../data/repositories/product_repository.dart';

class AddProductUseCase {
  final ProductRepository repository;

  AddProductUseCase(this.repository);

  Future<void> execute(ProductEntity product) async {
    await repository.addProduct(product);
  }
}