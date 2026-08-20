import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../../config/app_config.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  factory GoogleSheetsService() => _instance;
  GoogleSheetsService._internal();

  late SheetsApi _sheetsApi;
  bool _isInitialized = false;


  // Initialize Service Account Authentication
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Load service account credentials from the local asset
      final jsonStr = await rootBundle.loadString(
        'assets/secrets/service_account.json',
      );

      final credentials = jsonDecode(jsonStr) as Map<String, dynamic>;

      final accountCredentials =
      ServiceAccountCredentials.fromJson(credentials);

      final scopes = [SheetsApi.spreadsheetsScope];

      final authClient =
      await clientViaServiceAccount(accountCredentials, scopes);

      _sheetsApi = SheetsApi(authClient);
      _isInitialized = true;

      print(
        'Google Sheets Service initialized with Service Account successfully',
      );
    } catch (e) {
      print('Error initializing Google Sheets Service: $e');
      throw Exception('Failed to initialize Google Sheets: $e');
    }
  }

  // Get existing headers (the first row) of a sheet
  Future<List<String>> getHeaders(String sheetName) async {
    final values = await readSheet(sheetName);
    if (values.isEmpty) return [];

    return values.first.map((e) => e.toString()).toList();
  }

  // Ensure sheet exists and insert headers into the first row
  Future<void> insertHeaders(String sheetName, List<String> headers) async {
    await createSheetIfNotExists(sheetName);

    await writeToSheet(
      sheetName: sheetName,
      values: [headers],
      range: '$sheetName!A1',
    );
  }

  // Read data from a sheet
  Future<List<List<dynamic>>> readSheet(String sheetName) async {
    if (!_isInitialized) await init();

    try {
      final response = await _sheetsApi.spreadsheets.values.get(
        AppConfig.spreadsheetId,
        sheetName,
      );

      return response.values ?? [];
    } catch (e) {
      print('Error reading sheet $sheetName: $e');
      return [];
    }
  }

  // Write data to a sheet
  Future<void> writeToSheet({
    required String sheetName,
    required List<List<dynamic>> values,
    String? range,
  }) async {
    if (!_isInitialized) await init();

    try {
      final valueRange = ValueRange()
        ..values = values
        ..majorDimension = 'ROWS';

      final updateRange = range ?? '$sheetName!A1';

      await _sheetsApi.spreadsheets.values.update(
        valueRange,
        AppConfig.spreadsheetId,
        updateRange,
        valueInputOption: 'USER_ENTERED',
      );

      print('Data written to $sheetName successfully');
    } catch (e) {
      print('Error writing to sheet $sheetName: $e');
      throw Exception('Failed to write to sheet: $e');
    }
  }

  // Appends data to a sheet. If the sheet is empty, automatically writes [defaultHeaders] first.
  Future<void> appendToSheet({
    required String sheetName,
    required List<dynamic> rowData,
    List<String>? defaultHeaders,
  }) async {
    if (!_isInitialized) await init();

    try {
      // Check if the sheet has any existing rows
      final currentRows = await readSheet(sheetName);

      if (currentRows.isEmpty) {
        if (defaultHeaders != null && defaultHeaders.isNotEmpty) {
          print('📌 [SHEETS] Sheet "$sheetName" is empty. Inserting headers on Row 1 first...');
          await writeToSheet(
            sheetName: sheetName,
            values: [defaultHeaders],
            range: '$sheetName!A1',
          );
        }
      }

      final valueRange = ValueRange()
        ..values = [rowData]
        ..majorDimension = 'ROWS';

      await _sheetsApi.spreadsheets.values.append(
        valueRange,
        AppConfig.spreadsheetId,
        '$sheetName!A1',
        valueInputOption: 'USER_ENTERED',
        insertDataOption: 'INSERT_ROWS',
      );

      print('Data appended to $sheetName successfully');
    } catch (e) {
      print('Error appending to sheet $sheetName: $e');
      throw Exception('Failed to append to sheet: $e');
    }
  }

  // Update specific cell
  Future<void> updateCell({
    required String sheetName,
    required String cellReference,
    required dynamic value,
  }) async {
    if (!_isInitialized) await init();

    try {
      final valueRange = ValueRange()
        ..values = [
          [value]
        ]
        ..majorDimension = 'ROWS';

      await _sheetsApi.spreadsheets.values.update(
        valueRange,
        AppConfig.spreadsheetId,
        '$sheetName!$cellReference',
        valueInputOption: 'USER_ENTERED',
      );

      print('Cell $cellReference updated successfully');
    } catch (e) {
      print('Error updating cell: $e');
      throw Exception('Failed to update cell: $e');
    }
  }

  // Create a new sheet if it doesn't exist
  Future<void> createSheetIfNotExists(String sheetName) async {
    if (!_isInitialized) await init();

    try {
      final spreadsheet =
      await _sheetsApi.spreadsheets.get(AppConfig.spreadsheetId);
      final exists = spreadsheet.sheets?.any(
            (sheet) => sheet.properties?.title == sheetName,
      ) ??
          false;

      if (!exists) {
        final sheetProperties = SheetProperties()..title = sheetName;

        final addSheetRequest = AddSheetRequest()
          ..properties = sheetProperties;

        final batchUpdateRequest = BatchUpdateSpreadsheetRequest()
          ..requests = [Request()..addSheet = addSheetRequest];

        await _sheetsApi.spreadsheets.batchUpdate(
          batchUpdateRequest,
          AppConfig.spreadsheetId,
        );

        print('Sheet $sheetName created successfully');
      }
    } catch (e) {
      print('Error creating sheet $sheetName: $e');
    }
  }

  // Delete a sheet
  Future<void> deleteSheet(String sheetName) async {
    if (!_isInitialized) await init();

    try {
      final spreadsheet =
      await _sheetsApi.spreadsheets.get(AppConfig.spreadsheetId);
      final sheet = spreadsheet.sheets?.firstWhere(
            (sheet) => sheet.properties?.title == sheetName,
      );

      final sheetId = sheet?.properties?.sheetId;

      if (sheetId != null) {
        final deleteSheetRequest = DeleteSheetRequest()..sheetId = sheetId;
        final batchUpdateRequest = BatchUpdateSpreadsheetRequest()
          ..requests = [Request()..deleteSheet = deleteSheetRequest];

        await _sheetsApi.spreadsheets.batchUpdate(
          batchUpdateRequest,
          AppConfig.spreadsheetId,
        );

        print('Sheet $sheetName deleted successfully');
      }
    } catch (e) {
      print('Error deleting sheet $sheetName: $e');
    }
  }

  // Get all data from a sheet with headers
  Future<Map<String, List<dynamic>>> getSheetDataWithHeaders(
      String sheetName) async {
    final values = await readSheet(sheetName);
    if (values.isEmpty) return {};

    final headers = values.first.map((e) => e.toString()).toList();
    final data = <String, List<dynamic>>{};

    for (var i = 0; i < headers.length; i++) {
      data[headers[i]] = [];
      for (var j = 1; j < values.length; j++) {
        if (values[j].length > i) {
          data[headers[i]]!.add(values[j][i]);
        } else {
          data[headers[i]]!.add(null);
        }
      }
    }

    return data;
  }

  // Clear a sheet
  Future<void> clearSheet(String sheetName) async {
    if (!_isInitialized) await init();

    try {
      await _sheetsApi.spreadsheets.values.clear(
        ClearValuesRequest(),
        AppConfig.spreadsheetId,
        sheetName,
      );
      print('Sheet $sheetName cleared successfully');
    } catch (e) {
      print('Error clearing sheet $sheetName: $e');
    }
  }
}