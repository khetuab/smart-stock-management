import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/islamic_controller.dart';
import 'package:smart_stock/presentation/controllers/setup_controller.dart';
import 'package:smart_stock/presentation/controllers/theme_controller.dart';
import 'package:smart_stock/presentation/controllers/user_management_controller.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/category_controller.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/debt_controller.dart';
import '../../presentation/controllers/hijri_calender_controller.dart';
import '../../presentation/controllers/media_controller.dart';
import '../../presentation/controllers/notification_controller.dart';
import '../../presentation/controllers/product_controller.dart';
import '../../presentation/controllers/promotion_controller.dart';
import '../../presentation/controllers/quran_mushaf_controller.dart';
import '../../presentation/controllers/quran_page_controller.dart';
import '../../presentation/controllers/sale_controller.dart';
import '../../presentation/controllers/purchase_controller.dart';
import '../../presentation/controllers/report_controller.dart';
import '../../presentation/controllers/social_links_controller.dart';
import '../../presentation/controllers/zakat_controller.dart';
import '../../presentation/controllers/settings_controller.dart';
import '../../presentation/controllers/backup_controller.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/services/backup_service.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Services (Permanent - always available)
    Get.put(GoogleSheetsService(), permanent: true);
    Get.put(CloudinaryService(), permanent: true);
    Get.put(SharedPreferencesService(), permanent: true);
    Get.put(BackupService(), permanent: true);

    // All Controllers - Permanent (never deleted from memory)
    Get.put(AuthController(), permanent: true);
    Get.put(UserManagementController(), permanent: true);
    Get.put(PromotionController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    Get.put(MediaController(), permanent: true);
    Get.put(QuranReaderController(), permanent: true);
    Get.put(IslamicController(), permanent: true);
    Get.put(HijriCalendarController(), permanent: true);
    Get.put(IslamicController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(QuranMushafController(), permanent: true);
    Get.put(SocialLinksController(), permanent: true);
    Get.put(DebtController(), permanent: true);
    Get.put(DashboardController(), permanent: true);
    Get.put(ProductController(), permanent: true);
    Get.put(CategoryController(), permanent: true);
    Get.put(SaleController(), permanent: true);
    Get.put(PurchaseController(), permanent: true);
    Get.put(ReportController(), permanent: true);
    Get.put(SetupController(), permanent: true);
    Get.put(ZakatController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(BackupController(), permanent: true);
  }
}