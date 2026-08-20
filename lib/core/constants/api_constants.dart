class ApiConstants {
  // Google Sheets
  static const String googleSheetsBaseUrl = 'https://sheets.googleapis.com/v4';
  static const String spreadsheetId = 'YOUR_SPREADSHEET_ID';
  static const String apiKey = 'YOUR_API_KEY';

  // Cloudinary
  static const String cloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';
  static const String cloudName = 'YOUR_CLOUD_NAME';
  static const String uploadPreset = 'YOUR_UPLOAD_PRESET';

  // Timeouts
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  static const int sendTimeout = 30; // seconds
}