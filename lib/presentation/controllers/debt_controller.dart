import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/debt_model.dart';
import '../../data/services/google_sheets_service.dart';
import 'purchase_controller.dart';
import 'sale_controller.dart';

class DebtController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  var debts = <Debt>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;

  static const List<String> _headers = [
    'id',
    'type',
    'refId',
    'personName',
    'personPhone',
    'totalAmount',
    'amountPaid',
    'date',
    'dueDate',
    'notes',
    'status',
  ];

  /// Self-registering accessor to ensure the controller is available app-wide
  static DebtController get to {
    if (Get.isRegistered<DebtController>()) {
      return Get.find<DebtController>();
    }
    return Get.put(DebtController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    loadDebts();
  }

  List<Debt> get debtors =>
      debts.where((d) => d.type == 'receivable' && !d.isSettled).toList();

  List<Debt> get creditors =>
      debts.where((d) => d.type == 'payable' && !d.isSettled).toList();

  double get totalReceivables =>
      debtors.fold(0.0, (sum, d) => sum + d.balance);

  double get totalPayables =>
      creditors.fold(0.0, (sum, d) => sum + d.balance);

  List<Debt> filteredDebtors() {
    if (searchQuery.value.isEmpty) return debtors;
    return debtors
        .where((d) =>
        d.personName.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  List<Debt> filteredCreditors() {
    if (searchQuery.value.isEmpty) return creditors;
    return creditors
        .where((d) =>
        d.personName.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  void search(String query) => searchQuery.value = query;

  Future<void> _ensureHeadersExist() async {
    final existingData = await _sheets.getSheetDataWithHeaders('Debts');
    if (existingData.isEmpty) {
      await _sheets.writeToSheet(
        sheetName: 'Debts',
        values: [_headers],
      );
    }
  }

  Future<void> loadDebts() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Debts');
      await _ensureHeadersExist();

      final data = await _sheets.getSheetDataWithHeaders('Debts');
      debts.value = _parseDebts(data);
    } catch (e) {
      print('Error loading debts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Debt> _parseDebts(Map<String, List<dynamic>> data) {
    final list = <Debt>[];
    if (data.isEmpty) return list;

    final ids = data['id'] ?? [];
    final types = data['type'] ?? [];
    final refIds = data['refId'] ?? [];
    final names = data['personName'] ?? [];
    final phones = data['personPhone'] ?? [];
    final totals = data['totalAmount'] ?? [];
    final paids = data['amountPaid'] ?? [];
    final dates = data['date'] ?? [];
    final dueDates = data['dueDate'] ?? [];
    final notes = data['notes'] ?? [];
    final statuses = data['status'] ?? [];

    for (int i = 0; i < ids.length; i++) {
      if ((ids[i]?.toString() ?? '').isEmpty) continue;
      list.add(Debt(
        id: ids[i].toString(),
        type: i < types.length ? types[i]?.toString() ?? 'receivable' : 'receivable',
        refId: i < refIds.length ? refIds[i]?.toString() ?? '' : '',
        personName: i < names.length ? names[i]?.toString() ?? '' : '',
        personPhone: i < phones.length ? phones[i]?.toString() ?? '' : '',
        totalAmount: i < totals.length ? double.tryParse(totals[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        amountPaid: i < paids.length ? double.tryParse(paids[i]?.toString() ?? '0') ?? 0.0 : 0.0,
        date: i < dates.length ? dates[i]?.toString() ?? '' : '',
        dueDate: i < dueDates.length ? dueDates[i]?.toString() ?? '' : '',
        notes: i < notes.length ? notes[i]?.toString() ?? '' : '',
        status: i < statuses.length ? statuses[i]?.toString() ?? 'unpaid' : 'unpaid',
      ));
    }
    return list;
  }

  Future<void> addDebt({
    required String type,
    required String refId,
    required String personName,
    String personPhone = '',
    required double totalAmount,
    double amountPaid = 0.0,
    String dueDate = '',
    String notes = '',
  }) async {
    try {
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Debts');
      await _ensureHeadersExist();

      final now = DateTime.now();
      final debt = Debt(
        id: Helpers.generateId(),
        type: type,
        refId: refId,
        personName: personName.trim().isEmpty
            ? (type == 'receivable' ? 'Walk-in Customer' : 'Unnamed Supplier')
            : personName.trim(),
        personPhone: personPhone,
        totalAmount: totalAmount,
        amountPaid: amountPaid,
        date: now.toIso8601String().split('T')[0],
        dueDate: dueDate,
        notes: notes,
        status: amountPaid >= totalAmount ? 'paid' : (amountPaid > 0 ? 'partial' : 'unpaid'),
      );

      await _sheets.appendToSheet(
        sheetName: 'Debts',
        rowData: [
          debt.id,
          debt.type,
          debt.refId,
          debt.personName,
          debt.personPhone,
          debt.totalAmount.toString(),
          debt.amountPaid.toString(),
          debt.date,
          debt.dueDate,
          debt.notes,
          debt.status,
        ],
      );

      debts.add(debt);
    } catch (e) {
      print('Error adding debt: $e');
    }
  }

  Future<void> recordPayment(Debt debt, double amount) async {
    if (amount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Enter an amount greater than 0',
        colorText: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final newPaid = (debt.amountPaid + amount).clamp(0.0, debt.totalAmount);
      final newStatus = newPaid >= debt.totalAmount
          ? 'paid'
          : (newPaid > 0 ? 'partial' : 'unpaid');

      final updated = debt.copyWith(amountPaid: newPaid, status: newStatus);

      final index = debts.indexWhere((d) => d.id == debt.id);
      if (index != -1) {
        debts[index] = updated;
      }

      await _rewriteAllDebts();

      if (debt.type == 'payable') {
        await PurchaseController.to.applyDebtPayment(debt.refId, amount);
      } else if (debt.type == 'receivable') {
        await SaleController.to.applyDebtPayment(debt.refId, amount);
      }

      Get.snackbar(
        'Payment Recorded',
        newStatus == 'paid'
            ? '${debt.personName} is now fully settled'
            : '${debt.personName} now owes ${updated.balance.toStringAsFixed(2)}',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error recording payment: $e');
      Get.snackbar(
        'Error',
        'Failed to record payment: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _rewriteAllDebts() async {
    final values = <List<dynamic>>[_headers];
    for (var d in debts) {
      values.add([
        d.id,
        d.type,
        d.refId,
        d.personName,
        d.personPhone,
        d.totalAmount.toString(),
        d.amountPaid.toString(),
        d.date,
        d.dueDate,
        d.notes,
        d.status,
      ]);
    }
    await _sheets.writeToSheet(sheetName: 'Debts', values: values);
  }

  Future<void> refresh() => loadDebts();
}