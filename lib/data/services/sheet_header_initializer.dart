import 'package:flutter/foundation.dart';
import 'google_sheets_service.dart'; // Adjust path to your Google Sheets service instance

class SheetHeaderInitializer {
  final GoogleSheetsService _sheets;

  SheetHeaderInitializer(this._sheets);

  // Map sheet names to their required headers
  static final Map<String, List<String>> _sheetHeaders = {
    'Categories': [
      'id',
      'name',
      'description',
      'icon',
      'color',
      'productCount',
      'createdAt'
    ],
    'Products': [
      'id',
      'name',
      'category',
      'image',
      'purchasePrice',
      'sellingPrice',
      'quantity',
      'minQuantity',
      'barcode',
      'description',
      'dateAdded'
    ],
    'Sales': [
      'id',
      'productId',
      'productName',
      'quantity',
      'sellingPrice',
      'total',
      'date',
      'time',
      'status',
      'isCredit',
      'customerName',
      'customerPhone',
      'amountPaid',
      'listedPrice'
    ],
    'Purchases': [
      'id',
      'productId',
      'productName',
      'quantity',
      'purchasePrice',
      'total',
      'supplier',
      'date',
      'time',
      'isCredit',
      'amountPaid'
    ],
    'Debts':[
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
    ]
  };

  /// Checks each sheet and inserts headers if the first row is empty or incomplete
  Future<void> ensureHeadersExist() async {
    try {
      await _sheets.init();

      for (final entry in _sheetHeaders.entries) {
        final sheetName = entry.key;
        final requiredHeaders = entry.value;

        // Fetch existing headers/first row from sheet
        final existingHeaders = await _sheets.getHeaders(sheetName);

        if (existingHeaders == null || existingHeaders.isEmpty) {
          // Sheet has no headers — insert them into the first row
          await _sheets.insertHeaders(sheetName, requiredHeaders);
          debugPrint('Added headers to sheet: $sheetName');
        }
      }
    } catch (e) {
      debugPrint('Error initializing sheet headers: $e');
    }
  }
}