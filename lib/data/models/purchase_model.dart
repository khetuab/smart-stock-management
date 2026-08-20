class Purchase {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double purchasePrice;
  final double total;
  final String supplier;
  final String date;
  final String time;

  // --- Credit fields ---
  final bool isCredit;      // true = bought from supplier on credit (not yet paid)
  final double amountPaid;  // how much has actually been paid to the supplier

  Purchase({
    this.id = '',
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.total,
    this.supplier = '',
    this.date = '',
    this.time = '',
    this.isCredit = false,
    double? amountPaid,
  }) : amountPaid = amountPaid ?? (isCredit ? 0.0 : total);

  double get balanceDue => total - amountPaid;
  bool get isFullyPaid => balanceDue <= 0;

  Purchase copyWith({
    String? id,
    String? productId,
    String? productName,
    double? quantity,
    double? purchasePrice,
    double? total,
    String? supplier,
    String? date,
    String? time,
    bool? isCredit,
    double? amountPaid,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      total: total ?? this.total,
      supplier: supplier ?? this.supplier,
      date: date ?? this.date,
      time: time ?? this.time,
      isCredit: isCredit ?? this.isCredit,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'total': total,
      'supplier': supplier,
      'date': date,
      'time': time,
      'isCredit': isCredit,
      'amountPaid': amountPaid,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    final total = (map['total'] ?? 0).toDouble();
    final isCredit = map['isCredit'] == true || map['isCredit']?.toString().toLowerCase() == 'true';

    return Purchase(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      total: total,
      supplier: map['supplier'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      isCredit: isCredit,
      amountPaid: map['amountPaid'] != null
          ? (map['amountPaid']).toDouble()
          : (isCredit ? 0.0 : total),
    );
  }
}