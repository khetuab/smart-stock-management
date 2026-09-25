import 'package:get/get.dart';
import 'package:smart_stock/presentation/controllers/quran_mushaf_controller.dart';
import 'package:smart_stock/presentation/controllers/user_management_controller.dart';
import 'package:smart_stock/presentation/views/mushaf/quran_mushaf_screen.dart';
import 'package:smart_stock/presentation/views/settings/user_management_screen.dart';
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
import '../../presentation/controllers/media_controller.dart';
import '../../presentation/controllers/product_controller.dart';
import '../../presentation/controllers/purchase_controller.dart';
import '../../presentation/controllers/report_controller.dart';
import '../../presentation/controllers/sale_controller.dart';
import '../../presentation/controllers/settings_controller.dart';
import '../../presentation/controllers/social_links_controller.dart';
import '../../presentation/controllers/zakat_controller.dart';
import '../../presentation/views/categores/add_category_screen.dart';
import '../../presentation/views/categores/category_list_screen.dart';
import '../../presentation/views/categores/category_products_screen.dart';
import '../../presentation/views/customer/all_products.dart';
import '../../presentation/views/customer/customer_islamic_hub.dart';
import '../../presentation/views/debts/debts_screen.dart';
import '../../presentation/views/islamic/islamic_hub_screen.dart';
import '../../presentation/views/media/create_post_screen.dart';
import '../../presentation/views/media/media_feed_screen.dart';
import '../../presentation/views/orders/order_list_router.dart';
import '../../presentation/views/promotions/admin_promotions_screen.dart';
import '../../presentation/views/settings/admin_social_links_screen.dart';
import 'app_routes.dart';
import '../bindings/initial_binding.dart';
import 'fullscreen_dialog_transition.dart';

// Order & Islamic screens
import '../../presentation/views/orders/order_list_screen.dart';
import '../../presentation/views/orders/order_detail_screen.dart';
import '../../presentation/views/orders/create_order_screen.dart';
import '../../presentation/views/orders/order_chat_screen.dart';
import '../../presentation/views/islamic/quran_reader_screen.dart';
import '../../presentation/views/islamic/tasbih_screen.dart';
import '../../presentation/views/islamic/prayer_times_screen.dart';
import '../../presentation/views/islamic/qibla_screen.dart';
import '../../presentation/views/islamic/hijri_calendar_screen.dart';
import '../../presentation/views/notifications/notification_screen.dart';

// Controllers
import '../../presentation/controllers/order_controller.dart';
import '../../presentation/controllers/notification_controller.dart';
import '../../presentation/controllers/islamic_controller.dart';

// NEW: Role selection & customer-facing screens
import '../../presentation/views/auth/role_selection_screen.dart';
import '../../presentation/views/auth/customer_welcome_screen.dart';

import '../../presentation/views/customer/customer_home_screen.dart';
import '../../presentation/views/customer/customer_settings_screen.dart';


class AppPages {
  static const initial = AppRoutes.setup;

  static final pages = [
    // 0. DEVICE ROLE SELECTION (first run)
    GetPage(
      name: AppRoutes.islamicHub,
      page: () => const IslamicHubScreen(),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.islamicHubc,
      page: () => const IslamicHubScreenc(),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.customerWelcome,
      page: () => const CustomerWelcomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AuthController(), fenix: true);
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.mediaFeed,
      page: () => const MediaFeedScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MediaController(), fenix: true);
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.createPostScreen,
      page: () => const CreatePostScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MediaController(), fenix: true);
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

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
      name: AppRoutes.allProducts,
      page: () => const CustomerAllProductsScreen(),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => ProductController());
        Get.lazyPut(() => NotificationController());
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

    // ============================================================
    // ORDERING SYSTEM PAGES (shared by admin & customer)
    // ============================================================
    GetPage(
      name: AppRoutes.orders,
      page: () => const OrderListRouter(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.promotions,
      page: () => const AdminPromotionsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
      customTransition: SlideBottomGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.createOrder,
      page: () => const CreateOrderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
        Get.lazyPut(() => ProductController());
      }),
      customTransition: SlideBottomGetTransition(),
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage(
      name: AppRoutes.socialLinks,
      page: () => const AdminSocialLinksScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SocialLinksController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.quranmushaf,
      page: () => const QuranMushafScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QuranMushafController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
GetPage(
      name: AppRoutes.orderChat,
      page: () => const OrderChatScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OrderController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // ============================================================
    // ISLAMIC FEATURES PAGES (shared by admin & customer)
    // ============================================================
    GetPage(
      name: AppRoutes.quran,
      page: () => const QuranReaderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.quranReader,
      page: () => const QuranReaderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.tasbih,
      page: () => const TasbihScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.prayerTimes,
      page: () => const PrayerTimesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.qibla,
      page: () => const QiblaScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.hijriCalendar,
      page: () => const HijriCalendarScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => IslamicController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
   GetPage(
      name: AppRoutes.userManagement,
      page: () => const UserManagementScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => UserManagementController());
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ============================================================
    // NOTIFICATIONS PAGE
    // ============================================================
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationController());
      }),
      customTransition: SlideBottomGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // ============================================================
    // NEW: CUSTOMER-FACING PAGES
    // ============================================================
    GetPage(
      name: AppRoutes.customerHome,
      page: () => const CustomerHomeScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProductController(), fenix: true);
        Get.lazyPut(() => DashboardController(), fenix: true);
        Get.lazyPut(() => OrderController(), fenix: true);
      }),
      customTransition: FadeScaleGetTransition(),
      transitionDuration: const Duration(milliseconds: 350),
    ),
    GetPage(
      name: AppRoutes.customerSettings,
      page: () => const CustomerSettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController(), fenix: true);
      }),
      customTransition: FadeGetTransition(),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}