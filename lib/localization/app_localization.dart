import 'package:get/get.dart';
import 'package:smart_stock/localization/translations/am_et.dart';
import 'package:smart_stock/localization/translations/ar_sa.dart';
import 'package:smart_stock/localization/translations/en_us.dart';

/// Registers all supported language maps with GetX. Passed to
/// `GetMaterialApp(translations: AppLocalization())` in main.dart.
/// Every string wrapped with `'key'.tr` anywhere in the app resolves
/// through this table based on the currently active locale.
class AppLocalization extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': enUS,
    'am_ET': amET,
    'ar_SA': arSA,
  };
}