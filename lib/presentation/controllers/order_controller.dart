// lib/presentation/controllers/order_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/services/google_sheets_service.dart';
import 'auth_controller.dart';
import 'notification_controller.dart';
import 'product_controller.dart';

class OrderController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  AuthController get _auth => Get.find<AuthController>();
  ProductController get _products => Get.find<ProductController>();
  NotificationController get _notificationController => Get.find<NotificationController>();

  var orders = <Order>[].obs;
  var filteredOrders = <Order>[].obs;
  var isLoading = false.obs;
  var isSendingMessage = false.obs;
  var selectedOrder = Rxn<Order>();
  var searchQuery = ''.obs;

  // Filters
  var statusFilter = 'all'.obs;
  final List<String> statusOptions = ['all', 'pending', 'approved', 'rejected', 'completed', 'cancelled'];

  static const List<String> _headers = [
    'id', 'productId', 'productName', 'customerName', 'customerPhone', 'customerUsername',
    'quantity', 'offeredPrice', 'total', 'status', 'notes', 'stockReduced', 'createdAt',
    'updatedAt', 'messages',
  ];

  static OrderController get to {
    if (Get.isRegistered<OrderController>()) {
      return Get.find<OrderController>();
    }
    return Get.put(OrderController(), permanent: true);
  }

  bool get isAdmin => _auth.isAdmin;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }


  /// Marks every message the CURRENT viewer hasn't yet seen as seen.
  /// Idempotent — if nothing changed, it doesn't write to the sheet at
  /// all, so calling this on every chat-screen rebuild is safe.
  Future<void> markMessagesSeen(String orderId) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = orders[index];

    bool changed = false;
    final updatedMessages = order.messages.map((m) {
      if (isAdmin && !m.seenByAdmin) {
        changed = true;
        return m.copyWith(seenByAdmin: true);
      }
      if (!isAdmin && !m.seenByCustomer) {
        changed = true;
        return m.copyWith(seenByCustomer: true);
      }
      return m;
    }).toList();

    if (!changed) return;

    final updated = order.copyWith(messages: updatedMessages);
    await _persistOrder(updated);
    _applyLocally(updated);
  }

  /// Only the sender of a message can edit it — enforced here too, not
  /// just hidden in the UI.
  Future<void> editMessage(String orderId, String messageId, String newText) async {
    if (newText.trim().isEmpty) return;
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = orders[index];

    final target = order.messages.firstWhere((m) => m.id == messageId, orElse: () => order.messages.first);
    final isOwnMessage = isAdmin ? target.isAdmin : !target.isAdmin;
    if (!isOwnMessage || target.deleted) return;

    final updatedMessages = order.messages.map((m) {
      return m.id == messageId ? m.copyWith(text: newText.trim(), edited: true) : m;
    }).toList();

    final updated = order.copyWith(messages: updatedMessages, updatedAt: DateTime.now().toIso8601String());
    await _persistOrder(updated);
    _applyLocally(updated);
  }

  /// Soft-delete — keeps a "This message was deleted" tombstone in place
  /// (same behavior as Telegram) instead of removing the message and
  /// shifting the conversation around.
  Future<void> deleteMessage(String orderId, String messageId) async {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = orders[index];

    final target = order.messages.firstWhere((m) => m.id == messageId, orElse: () => order.messages.first);
    final isOwnMessage = isAdmin ? target.isAdmin : !target.isAdmin;
    if (!isOwnMessage) return;

    final updatedMessages = order.messages.map((m) {
      return m.id == messageId ? m.copyWith(deleted: true, text: '') : m;
    }).toList();

    final updated = order.copyWith(messages: updatedMessages, updatedAt: DateTime.now().toIso8601String());
    await _persistOrder(updated);
    _applyLocally(updated);
  }

  Future<void> _ensureHeadersExist() async {
    final rawRows = await _sheets.readSheet('Orders');

    if (rawRows.isEmpty) {
      await _sheets.writeToSheet(sheetName: 'Orders', values: [_headers]);
      return;
    }

    final currentHeaders = rawRows.first.map((h) => h?.toString() ?? '').toList();
    final isUpToDate = currentHeaders.length == _headers.length &&
        List.generate(_headers.length, (i) => currentHeaders[i] == _headers[i])
            .every((match) => match);

    if (isUpToDate) return;

    // The header row predates 'customerUsername' / 'stockReduced' being
    // added to the code. Every row is ALREADY being written in the newer,
    // longer format by _rowFor() — only row 1's labels are stale — so this
    // just replaces the header row and leaves every data row untouched.
    final allRows = List<List<dynamic>>.from(rawRows);
    allRows[0] = _headers;
    await _sheets.clearSheet('Orders');
    await _sheets.writeToSheet(sheetName: 'Orders', values: allRows);
  }

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Orders');
      await _ensureHeadersExist();

      final data = await _sheets.getSheetDataWithHeaders('Orders');
      final all = _parseOrders(data);

      // Enforced here, not just in the UI: a customer account only ever
      // gets its own orders back. The admin sees everything.
      orders.value = isAdmin
          ? all
          : all.where((o) => o.customerUsername == _auth.username.value).toList();

      applyFilters();
    } catch (e) {
      debugPrint('Error loading orders: $e');
      Get.snackbar('Error', 'Failed to load orders', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  List<Order> _parseOrders(Map<String, List<dynamic>> data) {
    final list = <Order>[];
    if (data.isEmpty) return list;

    List<dynamic> col(String key) => data[key] ?? [];
    String at(List<dynamic> c, int i) => i < c.length ? (c[i]?.toString() ?? '') : '';

    final ids = col('id');
    final productIds = col('productId');
    final productNames = col('productName');
    final customerNames = col('customerName');
    final customerPhones = col('customerPhone');
    final customerUsernames = col('customerUsername');
    final quantities = col('quantity');
    final offeredPrices = col('offeredPrice');
    final totals = col('total');
    final statuses = col('status');
    final notes = col('notes');
    final stockReducedCol = col('stockReduced');
    final createdAts = col('createdAt');
    final updatedAts = col('updatedAt');
    final messagesCol = col('messages');

    for (int i = 0; i < ids.length; i++) {
      final status = at(statuses, i);
      list.add(Order(
        id: at(ids, i),
        productId: at(productIds, i),
        productName: at(productNames, i),
        customerName: at(customerNames, i),
        customerPhone: at(customerPhones, i),
        customerUsername: at(customerUsernames, i),
        quantity: double.tryParse(at(quantities, i)) ?? 0.0,
        offeredPrice: double.tryParse(at(offeredPrices, i)) ?? 0.0,
        total: double.tryParse(at(totals, i)) ?? 0.0,
        status: status.isEmpty ? 'pending' : status,
        notes: at(notes, i),
        stockReduced: at(stockReducedCol, i).toLowerCase() == 'true',
        createdAt: at(createdAts, i),
        updatedAt: at(updatedAts, i),
        messages: Order.decodeMessages(at(messagesCol, i)),
      ));
    }
    return list;
  }

  List<dynamic> _rowFor(Order o) => [
    o.id,
    o.productId,
    o.productName,
    o.customerName,
    o.customerPhone,
    o.customerUsername,
    o.quantity,
    o.offeredPrice,
    o.total,
    o.status,
    o.notes,
    o.stockReduced.toString(),
    o.createdAt,
    o.updatedAt,
    Order.encodeMessages(o.messages),
  ];

  /// Writes [order] to its existing row if one is found, otherwise
  /// appends it as new. Replaces the old pattern of rewriting the whole
  /// sheet on every status change / message / price update.
  Future<void> _persistOrder(Order order) async {
    final rowIndex = await _sheets.findRowIndexById(
      sheetName: 'Orders',
      idColumn: 'id',
      id: order.id,
    );
    if (rowIndex != null) {
      await _sheets.updateRow(sheetName: 'Orders', rowIndex: rowIndex, rowData: _rowFor(order));
    } else {
      await _sheets.appendToSheet(sheetName: 'Orders', rowData: _rowFor(order));
    }
  }

  void _applyLocally(Order updated) {
    final index = orders.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      orders[index] = updated;
    } else {
      orders.add(updated);
    }
    if (selectedOrder.value?.id == updated.id) selectedOrder.value = updated;
    applyFilters();
  }

  void applyFilters() {
    var filtered = List<Order>.from(orders);

    if (statusFilter.value != 'all') {
      filtered = filtered.where((o) => o.status == statusFilter.value).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((o) =>
      o.productName.toLowerCase().contains(query) ||
          o.customerName.toLowerCase().contains(query)
      ).toList();
    }

    filteredOrders.value = filtered;
  }

  void search(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void filterByStatus(String status) {
    statusFilter.value = status;
    applyFilters();
  }

  void selectOrder(Order order) => selectedOrder.value = order;

  Future<void> createOrder({
    required String productId,
    required String productName,
    required String customerName,
    String customerPhone = '',
    required double quantity,
    required double offeredPrice,
    String notes = '',
  }) async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Orders');
      await _ensureHeadersExist();

      final now = DateTime.now().toIso8601String();
      final order = Order(
        id: Helpers.generateId(),
        productId: productId,
        productName: productName,
        customerName: customerName.trim(),
        customerPhone: customerPhone.trim(),
        customerUsername: _auth.username.value,
        quantity: quantity,
        offeredPrice: offeredPrice,
        total: quantity * offeredPrice,
        status: 'pending',
        notes: notes.trim(),
        stockReduced: false,
        createdAt: now,
        updatedAt: now,
      );

      await _sheets.appendToSheet(sheetName: 'Orders', rowData: _rowFor(order));

      orders.add(order);
      applyFilters();

     // _notificationController.addNotification(
      //   title: 'New Order Received',
      //   body: '${order.customerName} ordered ${order.quantity}x ${order.productName}',
      //   type: 'order',
      //   orderId: order.id,
      // );

      Get.snackbar(
        'Order Placed',
        'Your order has been submitted successfully!',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to place order: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Admin-only. Approves a pending order at its current (negotiated)
  /// price and deducts the matching stock from the product in the same
  /// step. [Order.stockReduced] guards against deducting twice if this
  /// gets called again (double-tap, retry after a flaky write, etc).
  Future<void> approveOrder(String orderId) async {
    if (!isAdmin) return;

    final index = orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = orders[index];
    if (order.status != 'pending') return;

    try {
      isLoading.value = true;

      if (!order.stockReduced) {
        await _products.reduceStock(order.productId, order.quantity);
      }

      final updated = order.copyWith(
        status: 'approved',
        stockReduced: true,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _persistOrder(updated);
      _applyLocally(updated);

      _notificationController.addNotification(
        title: 'Order Approved',
        body: 'Your order #${updated.id.substring(0, 8).toUpperCase()} was approved.',
        type: 'order',
        orderId: orderId,
      );

      Get.snackbar(
        'Order Approved',
        'Stock updated and the customer has been notified.',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      // Most commonly: not enough stock left. Order stays pending so the
      // admin can renegotiate quantity/price instead of it silently
      // going through.
      Get.snackbar('Cannot Approve', '$e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectOrder(String orderId, {String reason = ''}) async {
    if (!isAdmin) return;
    await updateOrderStatus(orderId, 'rejected', extraNote: reason);
  }

  Future<void> markCompleted(String orderId) async {
    if (!isAdmin) return;
    await updateOrderStatus(orderId, 'completed');
  }

  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'cancelled');
  }

  Future<void> updateOrderStatus(String orderId, String newStatus, {String extraNote = ''}) async {
    try {
      isLoading.value = true;
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return;
      final current = orders[index];

      final updated = current.copyWith(
        status: newStatus,
        updatedAt: DateTime.now().toIso8601String(),
        notes: extraNote.trim().isEmpty ? current.notes : '${current.notes}\n${extraNote.trim()}'.trim(),
      );

      await _persistOrder(updated);
      _applyLocally(updated);

      _notificationController.addNotification(
        title: 'Order Update',
        body: 'Order #${updated.id.substring(0, 8).toUpperCase()} is now $newStatus',
        type: 'order',
        orderId: orderId,
      );

      Get.snackbar('Status Updated', 'Order status changed to $newStatus', colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('Error updating order status: $e');
      Get.snackbar('Error', 'Failed to update order: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Admin-only. Lets the admin propose a new unit price mid-negotiation
  /// without changing the order's status — it stays 'pending' until
  /// explicitly approved.
  Future<void> proposeNewPrice(String orderId, double newPrice) async {
    if (!isAdmin || newPrice <= 0) return;
    try {
      isLoading.value = true;
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return;
      final order = orders[index];

      final updated = order.copyWith(
        offeredPrice: newPrice,
        total: newPrice * order.quantity,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _persistOrder(updated);
      _applyLocally(updated);

      Get.snackbar('Price Updated', 'New offer sent to the customer.', colorText: Colors.green, snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update price: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage(String orderId, String message) async {
    if (message.trim().isEmpty) return;

    try {
      isSendingMessage.value = true;
      final index = orders.indexWhere((o) => o.id == orderId);
      if (index == -1) return;
      final order = orders[index];

      // Sender identity now reflects who's actually logged in, instead
      // of always being hardcoded to 'Admin'.
      final senderName = isAdmin
          ? 'Admin'
          : (order.customerName.isNotEmpty ? order.customerName : _auth.username.value);

      final newMessage = OrderMessage(
        id: Helpers.generateId(),
        sender: senderName,
        text: message.trim(),
        timestamp: DateTime.now().toIso8601String(),
        isAdmin: isAdmin,
      );

      final updated = order.copyWith(
        messages: [...order.messages, newMessage],
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _persistOrder(updated);
      _applyLocally(updated);

      // _notificationController.addNotification(
      //   title: isAdmin ? 'New Message' : 'New Message from Customer',
      //   body: isAdmin
      //       ? 'Admin replied to your order #${orderId.substring(0, 8).toUpperCase()}'
      //       : '$senderName replied to order #${orderId.substring(0, 8).toUpperCase()}',
      //   type: 'message',
      //   orderId: orderId,
      // );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message: $e', colorText: Colors.red, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSendingMessage.value = false;
    }
  }

  int get pendingCount => orders.where((o) => o.status == 'pending').length;

  Future<void> refresh() => loadOrders();
}