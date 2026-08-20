class Product {
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

  Product({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image': image,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'barcode': barcode,
      'description': description,
      'dateAdded': dateAdded,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      image: map['image'] ?? '',
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      quantity: (map['quantity'] ?? 0).toDouble(),
      minQuantity: (map['minQuantity'] ?? 0).toDouble(),
      barcode: map['barcode'] ?? '',
      description: map['description'] ?? '',
      dateAdded: map['dateAdded'] ?? '',
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? image,
    double? purchasePrice,
    double? sellingPrice,
    double? quantity,
    double? minQuantity,
    String? barcode,
    String? description,
    String? dateAdded,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      image: image ?? this.image,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }
}