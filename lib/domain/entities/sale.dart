class SaleEntity {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double sellingPrice;
  final double total;
  final String date;
  final String time;
  final String status;

  SaleEntity({
    this.id = '',
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.sellingPrice,
    required this.total,
    this.date = '',
    this.time = '',
    this.status = 'completed',
  });
}