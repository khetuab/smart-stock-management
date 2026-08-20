class Report {
  final String id;
  final String type; // daily, weekly, monthly, custom
  final DateTime startDate;
  final DateTime endDate;
  final double totalSales;
  final double totalPurchases;
  final double estimatedProfit;
  final int totalTransactions;
  final int totalProducts;
  final Map<String, dynamic>? additionalData;
  final String generatedAt;

  Report({
    this.id = '',
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalPurchases,
    required this.estimatedProfit,
    required this.totalTransactions,
    required this.totalProducts,
    this.additionalData,
    this.generatedAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'estimatedProfit': estimatedProfit,
      'totalTransactions': totalTransactions,
      'totalProducts': totalProducts,
      'additionalData': additionalData,
      'generatedAt': generatedAt,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      totalSales: (map['totalSales'] ?? 0).toDouble(),
      totalPurchases: (map['totalPurchases'] ?? 0).toDouble(),
      estimatedProfit: (map['estimatedProfit'] ?? 0).toDouble(),
      totalTransactions: map['totalTransactions'] ?? 0,
      totalProducts: map['totalProducts'] ?? 0,
      additionalData: map['additionalData'],
      generatedAt: map['generatedAt'] ?? '',
    );
  }
}