import 'app_config.dart';

class GoogleSheetsConfig {
  static const String sheetId = AppConfig.spreadsheetId;

  // Sheet Names
  static const String productsSheet = 'Products';
  static const String salesSheet = 'Sales';
  static const String purchasesSheet = 'Purchases';
  static const String usersSheet = 'Users';
  static const String storeInfoSheet = 'StoreInfo';
  static const String settingsSheet = 'Settings';
  static const String zakatSheet = 'Zakat';
  static const String backupSheet = 'Backup';

  // Column Headers
  static const List<String> productColumns = [
    'id', 'name', 'category', 'image', 'purchasePrice',
    'sellingPrice', 'quantity', 'minQuantity', 'barcode',
    'description', 'dateAdded'
  ];

  static const List<String> saleColumns = [
    'id', 'productId', 'productName', 'quantity', 'sellingPrice',
    'total', 'date', 'time', 'status'
  ];

  static const List<String> purchaseColumns = [
    'id', 'productId', 'productName', 'quantity', 'purchasePrice',
    'total', 'supplier', 'date', 'time'
  ];

  static const List<String> userColumns = [
    'id', 'username', 'password', 'createdAt'
  ];

  static const List<String> storeInfoColumns = [
    'storeName', 'storeLogo', 'ownerName', 'currency',
    'language', 'zakatEnabled', 'themeColor', 'setupDate'
  ];
}