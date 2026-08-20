import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/setup_controller.dart';
import 'package:smart_stock/data/services/shared_preferences_service.dart';
import 'package:smart_stock/app/routes/app_pages.dart';
import 'package:smart_stock/app/routes/app_routes.dart';
import 'package:smart_stock/app/bindings/app_bindings.dart';
import 'package:smart_stock/presentation/controllers/theme_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/services/google_sheets_service.dart';
import 'data/services/sheet_header_initializer.dart';
import 'localization/app_localization.dart';
import 'localization/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = SharedPreferencesService();
  await prefs.init();
  Get.put(LocaleController(), permanent: true);

  // Register services in GetX container
  Get.put(prefs);
  final sheetsService = Get.put(GoogleSheetsService());
  Get.lazyPut(() => SetupController());

  // Make sure ThemeController is initialized before runApp if available
  Get.put(ThemeController());

  // Check and setup headers in Google Sheets on app startup
  final headerInitializer = SheetHeaderInitializer(sheetsService);
  await headerInitializer.ensureHeadersExist();

  // Print debug info
  print('📊 [MAIN] Setup completed: ${prefs.isSetupCompleted()}');
  print('📊 [MAIN] Logged in: ${prefs.isLoggedIn()}');

  // Determine initial route
  final isSetupCompleted = prefs.isSetupCompleted();
  final isLoggedIn = prefs.isLoggedIn();

  String initialRoute;
  if (!isSetupCompleted) {
    initialRoute = AppRoutes.setup;
  } else if (!isLoggedIn) {
    initialRoute = AppRoutes.login;
  } else {
    initialRoute = AppRoutes.dashboard;
  }

  print('📊 [MAIN] Initial route: $initialRoute');

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // Pass ThemeData directly instead of using Obx
    return GetMaterialApp(
      title: 'SmartStock',
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      initialBinding: AppBindings(),
      debugShowCheckedModeBanner: false,

      // Default Light Theme
      theme: themeController.lightTheme,

      // Default Dark Theme
      darkTheme: themeController.darkTheme,

      // Theme Mode state
      themeMode: themeController.themeMode.value,
      translations: AppLocalization(),
      locale: LocaleController.initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('am', 'ET'),
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}