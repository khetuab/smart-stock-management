import 'package:get/get.dart';
import '../../presentation/controllers/setup_controller.dart';
import '../../data/services/shared_preferences_service.dart';
import '../../data/services/google_sheets_service.dart';
import '../../data/services/cloudinary_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Only initialize what's needed at startup
    Get.put(SharedPreferencesService(), permanent: true);
    Get.lazyPut(() => SetupController(), fenix: true);
    Get.lazyPut(() => GoogleSheetsService(), fenix: true);
    Get.lazyPut(() => CloudinaryService(), fenix: true);
  }
}