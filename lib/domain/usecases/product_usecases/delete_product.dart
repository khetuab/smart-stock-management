import '../../../data/repositories/product_repository.dart';

class DeleteProductUseCase {
  final ProductRepository repository;

  DeleteProductUseCase(this.repository);

  Future<void> execute(String productId) async {
    await repository.deleteProduct(productId);
  }
}