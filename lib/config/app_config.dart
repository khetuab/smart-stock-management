class AppConfig {
  static const String appName = 'SmartStock';
  static const String appVersion = '1.0.0';

  // Google Sheets
  static const String spreadsheetId = '1SLL4MSsL32bYegfBBEUpv3DYt5Q3PhnhLm8_OLQ4-Go';
  //static const String spreadsheetId = '1ckoPAdFAkwpdJs8pKCKgYCCG6y2z11FMIkgHatnhhL8';
  static const String googleSheetsApiKey = 'AIzaSyAE742_2_iCx5Y_PqwXe3rvqtG5DD9IB1w';

  // Cloudinary
  static const String cloudinaryCloudName = 'uib2drmd';
  static const String cloudinaryApiKey = '367219468188789';
  static const String cloudinaryApiSecret = '07YbQS76yUqPdTWB6HR-h0_SDdM';
  static const String cloudinaryUploadPreset = 'smartstock';
  //static const String cloudinaryUploadPreset = 'papilon';

  // Shared Preferences Keys
  static const String prefIsLoggedIn = 'isLoggedIn';
  static const String prefUsername = 'username';
  static const String prefStoreName = 'storeName';
  static const String prefStoreLogo = 'storeLogo';
  static const String prefThemeColor = 'themeColor';
  static const String prefCurrency = 'currency';
  static const String prefLanguage = 'language';
  static const String prefZakatEnabled = 'zakatEnabled';
  static const String prefSetupCompleted = 'setupCompleted';
}