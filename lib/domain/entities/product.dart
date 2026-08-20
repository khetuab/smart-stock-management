class ProductEntity {
  final String id;
  final String name;
  final String category;
  final String image;
  final double purchasePrice;
  final double sellingPrice;
  final double quantity;
  final double minQuantity;
  final String barcode;
  final String description;
  final String dateAdded;

  ProductEntity({
    this.id = '',
    required this.name,
    this.category = '',
    this.image = '',
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minQuantity,
    this.barcode = '',
    this.description = '',
    this.dateAdded = '',
  });
}