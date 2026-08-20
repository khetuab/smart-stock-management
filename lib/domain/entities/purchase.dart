class PurchaseEntity {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double purchasePrice;
  final double total;
  final String supplier;
  final String date;
  final String time;

  PurchaseEntity({
    this.id = '',
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.purchasePrice,
    required this.total,
    this.supplier = '',
    this.date = '',
    this.time = '',
  });
}