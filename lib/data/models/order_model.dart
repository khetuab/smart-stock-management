// lib/data/models/order_model.dart

import 'dart:convert';

class Order {
  final String id;
  final String productId;
  final String productName;
  final String customerName;
  final String customerPhone;
  // Username of the logged-in account that placed the order. Used to
  // scope "my orders" for a customer account — customerName alone isn't
  // reliable since it's free-typed on the form and could collide.
  final String customerUsername;
  final double quantity;
  final double offeredPrice; // current negotiated unit price
  final double total;
  final String status; // 'pending', 'approved', 'rejected', 'completed', 'cancelled'
  final String notes;
  // Guards against deducting stock twice for the same order (e.g. a
  // double-tap on Approve, or a retried request after a flaky write).
  final bool stockReduced;
  final String createdAt;
  final String updatedAt;
  final List<OrderMessage> messages;

  Order({
    this.id = '',
    required this.productId,
    required this.productName,
    required this.customerName,
    this.customerPhone = '',
    this.customerUsername = '',
    required this.quantity,
    required this.offeredPrice,
    required this.total,
    this.status = 'pending',
    this.notes = '',
    this.stockReduced = false,
    this.createdAt = '',
    this.updatedAt = '',
    this.messages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerUsername': customerUsername,
      'quantity': quantity,
      'offeredPrice': offeredPrice,
      'total': total,
      'status': status,
      'notes': notes,
      'stockReduced': stockReduced,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      customerUsername: map['customerUsername']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '0') ?? 0.0,
      offeredPrice: double.tryParse(map['offeredPrice']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(map['total']?.toString() ?? '0') ?? 0.0,
      status: map['status']?.toString() ?? 'pending',
      notes: map['notes']?.toString() ?? '',
      stockReduced: map['stockReduced'] == true ||
          map['stockReduced']?.toString().toLowerCase() == 'true',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
      messages: (map['messages'] as List?)
          ?.map((m) => OrderMessage.fromMap(m as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Order copyWith({
    String? id,
    String? productId,
    String? productName,
    String? customerName,
    String? customerPhone,
    String? customerUsername,
    double? quantity,
    double? offeredPrice,
    double? total,
    String? status,
    String? notes,
    bool? stockReduced,
    String? createdAt,
    String? updatedAt,
    List<OrderMessage>? messages,
  }) {
    return Order(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerUsername: customerUsername ?? this.customerUsername,
      quantity: quantity ?? this.quantity,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      stockReduced: stockReduced ?? this.stockReduced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  /// Serializes messages into one string so they fit in a single Google
  /// Sheets cell.
  static String encodeMessages(List<OrderMessage> messages) =>
      jsonEncode(messages.map((m) => m.toMap()).toList());

  /// Reverses [encodeMessages]. Tolerant of an empty or corrupt cell so
  /// one bad row never breaks loading the rest of the sheet — this was
  /// previously not implemented at all, which is why chat messages never
  /// survived a reload.
  static List<OrderMessage> decodeMessages(String raw) {
    if (raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => OrderMessage.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}


class OrderMessage {
  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final bool isAdmin;
  final bool edited;
  final bool deleted;
  final bool seenByAdmin;
  final bool seenByCustomer;

  OrderMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isAdmin,
    this.edited = false,
    this.deleted = false,
    bool? seenByAdmin,
    bool? seenByCustomer,
  })  : seenByAdmin = seenByAdmin ?? isAdmin,   // sender trivially "sees" their own message
        seenByCustomer = seenByCustomer ?? !isAdmin;

  OrderMessage copyWith({
    String? text,
    bool? edited,
    bool? deleted,
    bool? seenByAdmin,
    bool? seenByCustomer,
  }) {
    return OrderMessage(
      id: id,
      sender: sender,
      text: text ?? this.text,
      timestamp: timestamp,
      isAdmin: isAdmin,
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      seenByAdmin: seenByAdmin ?? this.seenByAdmin,
      seenByCustomer: seenByCustomer ?? this.seenByCustomer,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender': sender,
    'text': text,
    'timestamp': timestamp,
    'isAdmin': isAdmin,
    'edited': edited,
    'deleted': deleted,
    'seenByAdmin': seenByAdmin,
    'seenByCustomer': seenByCustomer,
  };

  factory OrderMessage.fromMap(Map<String, dynamic> map) => OrderMessage(
    id: map['id']?.toString() ?? '',
    sender: map['sender']?.toString() ?? '',
    text: map['text']?.toString() ?? '',
    timestamp: map['timestamp']?.toString() ?? '',
    isAdmin: map['isAdmin'] == true,
    edited: map['edited'] == true,
    deleted: map['deleted'] == true,
    seenByAdmin: map['seenByAdmin'] == true,
    seenByCustomer: map['seenByCustomer'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'timestamp': timestamp,
    'isAdmin': isAdmin,
    'edited': edited,
    'deleted': deleted,
    'seenByAdmin': seenByAdmin,
    'seenByCustomer': seenByCustomer,
  };

  factory OrderMessage.fromJson(Map<String, dynamic> json) => OrderMessage(
    id: json['id']?.toString() ?? '',
    sender: json['sender']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    timestamp: json['timestamp']?.toString() ?? '',
    isAdmin: json['isAdmin'] == true,
    edited: json['edited'] == true,
    deleted: json['deleted'] == true,
    seenByAdmin: json['seenByAdmin'] == true,
    seenByCustomer: json['seenByCustomer'] == true,
  );
}
