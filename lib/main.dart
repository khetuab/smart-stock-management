import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/setup_controller.dart';
import 'package:smart_stock/data/services/shared_preferences_service.dart';
import 'package:smart_stock/app/routes/app_pages.dart';
import 'package:smart_stock/app/routes/app_routes.dart';
import 'package:smart_stock/app/bindings/app_bindings.dart';
import 'package:smart_stock/presentation/controllers/theme_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/route_observer.dart';
import 'data/services/google_sheets_service.dart';
import 'data/services/sheet_header_initializer.dart';
import 'localization/app_localization.dart';
import 'localization/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = SharedPreferencesService();
  await prefs.init();
  Get.put(LocaleController(), permanent: true);

  Get.put(prefs);
  final sheetsService = Get.put(GoogleSheetsService());
  Get.lazyPut(() => SetupController());
  Get.put(ThemeController());

  final headerInitializer = SheetHeaderInitializer(sheetsService);
  await headerInitializer.ensureHeadersExist();

  print('📊 [MAIN] Setup completed: ${prefs.isSetupCompleted()}');
  print('📊 [MAIN] Logged in: ${prefs.isLoggedIn()}');

  final isLoggedIn = prefs.isLoggedIn();
  final guestPhone = prefs.getGuestPhone();
  final role = prefs.getRole();

  print('📊 [MAIN] Logged in: $isLoggedIn, Role: $role');

  String initialRoute;
  if (isLoggedIn && role == 'admin') {
    initialRoute = AppRoutes.dashboard;
  } else if (isLoggedIn && role == 'customer') {
    initialRoute = AppRoutes.customerHome;
  } else {
    initialRoute = AppRoutes.customerHome;
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

    return Obx(() {
      return GetMaterialApp(
        title: 'Sadat Mejlis',
        initialRoute: initialRoute,
        getPages: AppPages.pages,
        initialBinding: AppBindings(),
        debugShowCheckedModeBanner: false,
        theme: themeController.lightTheme,     // re-read fresh every rebuild
        darkTheme: themeController.darkTheme,  // re-read fresh every rebuild
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
        navigatorObservers: [mediaRouteObserver],
      );
    });
  }
}

//{
//  "type": "service_account",
//  "project_id": "aregenkibet",
//  "private_key_id": "db104705e53662b3bed80208bf92fd2dbc0f98a2",
//  "private_key":     "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC8YQvpYTt3+OBK\nxlCHYrudw7uVJ4UdMGF2BOIDYxbEloiLO6oDqXeOwtmKS+dJ2BL/0/y5Ozg3Y7GV\n3UYY2EVldiLAaRC8DX/fPLj89MMDd48nH8FO0s780vhf4DtWa72p/QCU0aZvLro8\nk8ElAzbD1W+yTgDeUs9yq9nnF4i/4lEsbJ2evjArBhN04z6tRAP4Burp7qv0lSpL\n+Dc5/HvWG9GccOgkYtwDvnFXHpKrS63i23iSTVStzmdGS3laxp/mYAYa3XVF/iw9\n6EFqjureBl1ljN2lTLUYDssbU1jbs9/R7Lzw86l6FgzU/on0DRxvCJxojvRt4brx\nZ1mH4oDRAgMBAAECggEAIe6lM6O1D5Y/6JgyV0C8pN1mA6b7vldBpv2YLJ4DsuOe\nst3LcR9sjsWgY93qSo3mVji8NC1roeaOTX1vK/iA/5a5CcmjHwybdP2+IKqCGjTG\nD3kT2/vzFu11meeNKLL9lgohuazN+wcCuviueNlMWxguJ4MPevyVq4UzGgJOOqnc\nwIxfR1El06TNw26XAVI6NW3ES+mKbePIAz1Dp5wPThCZ9CqY2zv6qsW+U8mrpeL1\ngsNEyrG3KdzvaYPzgsV3YFgnUwaAIHoUudKthIGf3QUTiaGomv4G0uU04WR8AR1g\nVlH2qwOuNyTHyNJ75gl11L0e02J5KIH/hsM+V9PjlQKBgQD6rRk2uum+Gv5TCPqI\njp4g8b63Aan2U8u3tjxOUO4cIbRrAuNGvQvhiuEXaj1risxoOQTpFJ/kfSlc6LsY\niKmwyifmR8MvYfG8q2l2NWixOtkVEKNjozZlzyw2KcYlxwLSMkUJU7OOS5edPoKt\n7UlOUWIm5wFjXTIla4XZLdV+bwKBgQDAYT63rRBs10PbC+YOZ3w9HVAUpLiMFy+4\nN6I26qrF7bMa8X+kh7LMQ+YyZwN4zhQHEBHFrzJaZ65Q5j3BSO37MXs/suGl9YXU\nADztRZsPUIitAM998NrfhKZ5TY5iNm0lOWwLYHq9SUaeTrhNvC4L31kjHG0MSKzO\nvC/ZgA+UvwKBgQCEMrlzVYtjiFTLcZa+YYgfE55iYOxDTdnHnsGbA68vAs9lB/bY\nHWagoV8nvA18I4y9AiUGzqusEh24M7xHqfrjkxkLppjW6i5UM4nAn1YA8Wn+Y/Hm\n3/IWKvXD8q/eyF9CfuRNkOjGiDMC6C5+jv7z4JOEtJrUzhdeCKBj8nn+3QKBgCpL\n9ycZFNhpR9D8P7uBAy7IqBex06VxX5uIF9EtLRjRVySgXikFcMk6UH1aasf/vyWC\nYfXtvAtmakv9IyzA5RnqWie6I6SCY8cluj+Mozftw+8Nk5EkCGtGVferlpd/UeXy\nRxAFSVceqjkaI6lrq1AO7iErGcqum9fkRjzyy/ovAoGBAMa80W6u3mwGQtGEQI/F\nRkAYtePf9lG9lanvTjo+nMZV9s2XSn8fe7t/e/xHqZFcgqerT0alFs7TZVlRmd2y\nGW7ikVtbESGAd15d6U3D60LP4g2GoA2EzaJkoxJuyYUaNrrETV+Ae6q6RWbLcWE4\nkat7wajiQ0TDkfynBcqQ6ojU\n-----END PRIVATE KEY-----\n",
//  "client_email": "sheets-writer@aregenkibet.iam.gserviceaccount.com",
//  "client_id": "111773151467757602785",
//  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
//  "token_uri": "https://oauth2.googleapis.com/token",
//  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
//  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/sheets-writer%40aregenkibet.iam.gserviceaccount.com",
//  "universe_domain": "googleapis.com"
//}