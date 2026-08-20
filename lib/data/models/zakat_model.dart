class ZakatRecord {
  final String id;
  final double inventoryValue;
  final double cashBalance;
  final double bankBalance;
  final double goldValue;
  final double silverValue;
  final double otherAssets;
  final double totalAssets;
  final double nisabThreshold;
  final bool isAboveNisab;
  final double zakatDue;
  final String calculatedAt;

  ZakatRecord({
    this.id = '',
    required this.inventoryValue,
    required this.cashBalance,
    required this.bankBalance,
    required this.goldValue,
    required this.silverValue,
    required this.otherAssets,
    required this.totalAssets,
    required this.nisabThreshold,
    required this.isAboveNisab,
    required this.zakatDue,
    this.calculatedAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inventoryValue': inventoryValue,
      'cashBalance': cashBalance,
      'bankBalance': bankBalance,
      'goldValue': goldValue,
      'silverValue': silverValue,
      'otherAssets': otherAssets,
      'totalAssets': totalAssets,
      'nisabThreshold': nisabThreshold,
      'isAboveNisab': isAboveNisab,
      'zakatDue': zakatDue,
      'calculatedAt': calculatedAt,
    };
  }

  factory ZakatRecord.fromMap(Map<String, dynamic> map) {
    return ZakatRecord(
      id: map['id'] ?? '',
      inventoryValue: (map['inventoryValue'] ?? 0).toDouble(),
      cashBalance: (map['cashBalance'] ?? 0).toDouble(),
      bankBalance: (map['bankBalance'] ?? 0).toDouble(),
      goldValue: (map['goldValue'] ?? 0).toDouble(),
      silverValue: (map['silverValue'] ?? 0).toDouble(),
      otherAssets: (map['otherAssets'] ?? 0).toDouble(),
      totalAssets: (map['totalAssets'] ?? 0).toDouble(),
      nisabThreshold: (map['nisabThreshold'] ?? 0).toDouble(),
      isAboveNisab: map['isAboveNisab'] ?? false,
      zakatDue: (map['zakatDue'] ?? 0).toDouble(),
      calculatedAt: map['calculatedAt'] ?? '',
    );
  }
}