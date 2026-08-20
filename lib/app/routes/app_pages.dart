import 'package:get/get.dart';
import 'package:smart_stock/presentation/views/setup/setup_wizard_screen.dart';
import 'package:smart_stock/presentation/views/auth/login_screen.dart';
import 'package:smart_stock/presentation/views/dashboard/dashboard_screen.dart';
import 'package:smart_stock/presentation/views/products/product_list_screen.dart';
import 'package:smart_stock/presentation/views/products/add_product_screen.dart';
import 'package:smart_stock/presentation/views/products/product_detail_screen.dart';
import 'package:smart_stock/presentation/views/sales/sale_screen.dart';
import 'package:smart_stock/presentation/views/sales/sale_history_screen.dart';
import 'package:smart_stock/presentation/views/sales/sale_detail_screen.dart';
import 'package:smart_stock/presentation/views/purchases/purchase_screen.dart';
import 'package:smart_stock/presentation/views/purchases/purchase_history_screen.dart';
import 'package:smart_stock/presentation/views/reports/reports_screen.dart';
import 'package:smart_stock/presentation/views/reports/report_detail_screen.dart';
import 'package:smart_stock/presentation/views/zakat/zakat_screen.dart';
import 'package:smart_stock/presentation/views/low_stock/low_stock_screen.dart';
import 'package:smart_stock/presentation/views/settings/settings_screen.dart';
import 'package:smart_stock/presentation/views/settings/change_password_screen.dart';
import 'package:smart_stock/presentation/views/settings/backup_screen.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/backup_controller.dart';
import '../../presentation/controllers/category_controller.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/debt_controller.dart';
import '../../presentation/controllers/product_controller.dart';
import '../../presentation/controllers/purchase_controller.dart';
import '../../presentation/controllers/report_controller.dart';
import '../../presentation/controllers/sale_controller.dart';
import '../../presentation/controllers/settings_controller.dart';
import '../../presentation/controllers/zakat_controller.dart';
import '../../presentation/views/categores/add_category_screen.dart';
import '../../presentation/views/categores/category_list_screen.dart';
import '../../presentation/views/categores/category_products_screen.dart';
import '../../presentation/views/debts/debts_screen.dart';
import 'app_routes.dart';
import '../bindings/initial_binding.dart';
import 'fullscreen_dialog_transition.dart';

class AppPages {
  static const initial = AppRoutes.setup;

  static final pages = [
    // 1. SETUP
    GetPage(
      name: AppRoutes.setup,
      page: () => const SetupWizardScreen(),
      binding: InitialBinding(),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 2. AUTH & DASHBOARD
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // 3. PRODUCTS
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController(), fenix: true);
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddProductScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () {
        final product = Get.arguments as Product?;
        return ProductDetailScreen(product: product);
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // 4. CATEGORIES
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoryListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CategoryController());
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.addCategory,
      page: () => const AddCategoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => CategoryController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.categoryProducts,
      page: () {
        final category = Get.arguments as Category?;
        return CategoryProductsScreen(category: category ?? Category(name: ''));
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 5. SALES
    GetPage(
      name: AppRoutes.sales,
      page: () => const SaleScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SaleController());
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.saleHistory,
      page: () => const SaleHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SaleController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.saleDetail,
      page: () {
        final sale = Get.arguments as Sale?;
        return SaleDetailScreen(sale: sale);
      },
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SaleController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // 6. PURCHASES
    GetPage(
      name: AppRoutes.purchases,
      page: () => const PurchaseScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PurchaseController());
        Get.lazyPut(() => ProductController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.purchaseHistory,
      page: () => const PurchaseHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => PurchaseController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 7. REPORTS
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReportController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.reportDetail,
      page: () => const ReportDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ReportController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // 8. SPECIAL FEATURES
    GetPage(
      name: AppRoutes.zakat,
      page: () => const ZakatScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ZakatController());
      }),
      customTransition: ElasticZoomGetTransition(),
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: AppRoutes.lowStock,
      page: () => const LowStockScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController());
      }),
      customTransition: ElasticZoomGetTransition(),
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // 9. SETTINGS & UTILITIES
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SettingsController());
        Get.lazyPut(() => BackupController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.backup,
      page: () => const BackupScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => BackupController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.debt,
      page: () => const DebtsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DebtController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
  ];
}