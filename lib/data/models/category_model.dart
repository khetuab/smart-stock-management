class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int productCount;
  final String createdAt;

  Category({
    this.id = '',
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.productCount = 0,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description ?? '',
      'icon': icon ?? '',
      'color': color ?? '',
      'productCount': productCount,
      'createdAt': createdAt,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '',
      productCount: int.tryParse(map['productCount']?.toString() ?? '0') ?? 0,
      createdAt: map['createdAt'] ?? '',
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? productCount,
    String? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}