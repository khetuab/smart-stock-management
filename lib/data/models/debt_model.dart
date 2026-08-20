class Debt {
  final String id;
  final String type;        // 'receivable' = customer owes you | 'payable' = you owe supplier
  final String refId;       // linked Sale.id or Purchase.id
  final String personName;  // customer name or supplier name
  final String personPhone;
  final double totalAmount;
  final double amountPaid;
  final String date;
  final String dueDate;     // optional
  final String notes;
  final String status;      // 'unpaid' | 'partial' | 'paid'

  Debt({
    required this.id,
    required this.type,
    required this.refId,
    required this.personName,
    this.personPhone = '',
    required this.totalAmount,
    this.amountPaid = 0.0,
    required this.date,
    this.dueDate = '',
    this.notes = '',
    required this.status,
  });

  double get balance => totalAmount - amountPaid;
  bool get isSettled => balance <= 0;

  Debt copyWith({
    String? id,
    String? type,
    String? refId,
    String? personName,
    String? personPhone,
    double? totalAmount,
    double? amountPaid,
    String? date,
    String? dueDate,
    String? notes,
    String? status,
  }) {
    return Debt(
      id: id ?? this.id,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      personName: personName ?? this.personName,
      personPhone: personPhone ?? this.personPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'refId': refId,
      'personName': personName,
      'personPhone': personPhone,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'date': date,
      'dueDate': dueDate,
      'notes': notes,
      'status': status,
    };
  }
}