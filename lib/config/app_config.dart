class AppConfig {
  static const String appName = 'Ethio Sadat';
  static const String appVersion = '1.0.0';

  // Google Sheets
  ///static const String spreadsheetId = '1SLL4MSsL32bYegfBBEUpv3DYt5Q3PhnhLm8_OLQ4-Go';  --- default smart stock
  static const String spreadsheetId = '1tUdQa3onAJek47Y8DYYP9D3uK7mEWS95AWPcVW4WKic';

  ///static const String googleSheetsApiKey = 'AIzaSyAE742_2_iCx5Y_PqwXe3rvqtG5DD9IB1w';  --- default smart stock
  static const String googleSheetsApiKey = 'AIzaSyDXA5JCCpeTg7P16_naETQ4p0WtM118Chs';

  // Cloudinary
  /// static const String cloudinaryCloudName = 'uib2drmd';
  /// static const String cloudinaryApiKey = '367219468188789';
  /// static const String cloudinaryApiSecret = '07YbQS76yUqPdTWB6HR-h0_SDdM';
  /// static const String cloudinaryUploadPreset = 'smartstock';

  static const String cloudinaryCloudName = 's4sm66jl';
  static const String cloudinaryApiKey = '526938976333814';
  static const String cloudinaryApiSecret = 'Q1kzJiygo_idYX_ESuSp_STndRA';
  static const String cloudinaryUploadPreset = 'ethiosadat';
  static const String adminTelegramUsername = 'Ahmuti';
  static const String telegramOrderIntro = 'New Order Request';


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