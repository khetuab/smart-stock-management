class Sale {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double sellingPrice;
  final double listedPrice;
  final double total;
  final String date;
  final String time;
  final String status; // 'completed' | 'cancelled'

  // --- Credit fields ---
  final bool isCredit;
  final String customerName;
  final String customerPhone;
  final double amountPaid; // Tracks partial or total collections

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    double? listedPrice,
    required this.total,
    required this.date,
    required this.time,
    required this.status,
    this.isCredit = false,
    this.customerName = '',
    this.customerPhone = '',
    double? amountPaid,
  })  : listedPrice = listedPrice ?? sellingPrice,
        amountPaid = amountPaid ?? (isCredit ? 0.0 : total);

  double get balanceDue => (total - amountPaid).clamp(0.0, double.infinity);
  bool get isFullyPaid => balanceDue <= 0;

  Sale copyWith({
    String? id,
    String? productId,
    String? productName,
    double? quantity,
    double? sellingPrice,
    double? listedPrice,
    double? total,
    String? date,
    String? time,
    String? status,
    bool? isCredit,
    String? customerName,
    String? customerPhone,
    double? amountPaid,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      listedPrice: listedPrice ?? this.listedPrice,
      total: total ?? this.total,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      isCredit: isCredit ?? this.isCredit,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      amountPaid: amountPaid ?? this.amountPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'listedPrice': listedPrice,
      'total': total,
      'date': date,
      'time': time,
      'status': status,
      'isCredit': isCredit,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'amountPaid': amountPaid,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    final totalVal = double.tryParse(map['total']?.toString() ?? '0') ?? 0.0;
    final isCreditVal = map['isCredit']?.toString().toLowerCase() == 'true' || map['isCredit'] == true;
    final sellingPriceVal = double.tryParse(map['sellingPrice']?.toString() ?? '0') ?? 0.0;

    return Sale(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0.0,
      sellingPrice: sellingPriceVal,
      listedPrice: double.tryParse(map['listedPrice']?.toString() ?? '') ?? sellingPriceVal,
      total: totalVal,
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      status: map['status']?.toString() ?? 'completed',
      isCredit: isCreditVal,
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      amountPaid: map['amountPaid'] != null
          ? double.tryParse(map['amountPaid'].toString())
          : (isCreditVal ? 0.0 : totalVal),
    );
  }
}