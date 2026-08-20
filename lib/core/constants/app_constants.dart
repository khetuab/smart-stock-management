class AppConstants {
  static const String appName = 'SmartStock';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Smart Inventory & Sales Management System';

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';

  // Pagination
  static const int pageSize = 20;
  static const int maxRecentItems = 5;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Categories
  static const List<String> defaultCategories = [
    'Electronics',
    'Clothing',
    'Food & Beverages',
    'Pharmacy',
    'Hardware',
    'Cosmetics',
    'Stationery',
    'Other'
  ];

  // Currencies
  static const List<String> currencies = ['ETB', 'USD', 'EUR', 'GBP', 'AED'];

  // Languages
  static const List<String> languages = ['English', 'Amharic', 'Arabic'];

  // Zakat
  static const double zakatRate = 0.025; // 2.5%
  static const double nisabGold = 87.48; // grams
  static const double nisabSilver = 612.36; // grams
}