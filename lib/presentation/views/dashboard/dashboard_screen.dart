import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/widgets/promotion_banner_carousel.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/dashboard_header.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                snap: false,
                elevation: 0,
                scrolledUnderElevation: 4,
                surfaceTintColor: scheme.surface,
                backgroundColor: scheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    tooltip: 'refresh'.tr,
                    onPressed: controller.refreshDashboard,
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Obx(
                        () => Text(
                      controller.storeName.value.isEmpty
                          ? 'dashboard'.tr
                          : controller.storeName.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _StoreMeshHeaderPainter(
                          primaryColor: scheme.primary,
                          secondaryColor: scheme.tertiary,
                          isDark: isDark,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 48,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                backgroundImage: controller.storeLogo.value.isNotEmpty
                                    ? NetworkImage(controller.storeLogo.value)
                                    : null,
                                child: controller.storeLogo.value.isEmpty
                                    ? const Icon(Icons.storefront_rounded,
                                    color: Colors.white, size: 20)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${'welcomeBack'.tr}, ${authController.username.value.isNotEmpty ? authController.username.value : 'owner'.tr}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'retailInventoryHub'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const ActiveStorePill(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PromotionBannerCarousel(),
                      _buildQuickActions(context, scheme, isDark)
                          .animate()
                          .fadeIn(delay: 50.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      DashboardSectionHeader(title: 'overview'.tr),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.3,
                        children: [
                          DashboardStatCard(
                            title: 'totalProducts'.tr,
                            value: controller.totalProducts.value.toString(),
                            icon: Icons.inventory_2_rounded,
                            accent: scheme.primary,
                          ),
                          DashboardStatCard(
                            title: 'inventoryValue'.tr,
                            value: controller.formatCurrency(
                                controller.inventoryValue.value),
                            icon: Icons.account_balance_wallet_rounded,
                            accent: const Color(0xFF10B981),
                          ),
                          DashboardStatCard(
                            title: 'todaysSales'.tr,
                            value: controller.formatCurrency(
                                controller.todaySales.value),
                            icon: Icons.auto_graph_rounded,
                            accent: const Color(0xFFF97316),
                          ),
                          DashboardStatCard(
                            title: 'lowStockItems'.tr,
                            value: controller.lowStockCount.value.toString(),
                            icon: Icons.warning_amber_rounded,
                            accent: scheme.error,
                          ),
                          DashboardStatCard(
                            title: 'youAreOwed'.tr,
                            value: controller.formatCurrency(controller.totalReceivables),
                            icon: Icons.arrow_downward_rounded,
                            accent: const Color(0xFF10B981),
                          ),
                          DashboardStatCard(
                            title: 'youOwe'.tr,
                            value: controller.formatCurrency(controller.totalPayables),
                            icon: Icons.arrow_upward_rounded,
                            accent: const Color(0xFFEF4444),
                          ),
                        ],
                      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      SalesSummaryCard(
                        weeklyLabel: 'weeklyPerformance'.tr,
                        weeklyValue: controller.formatCurrency(
                            controller.weeklySales.value),
                        monthlyLabel: 'monthlyPerformance'.tr,
                        monthlyValue: controller.formatCurrency(
                            controller.monthlySales.value),
                      ).animate().fadeIn(delay: 250.ms, duration: 300.ms),

                      const SizedBox(height: 24),

                      if (controller.lowStockCount.value > 0) ...[
                        LowStockBanner(
                          count: controller.lowStockCount.value,
                          onTap: () => Get.toNamed('/low-stock'),
                        ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                        const SizedBox(height: 24),
                      ],

                      DashboardSectionHeader(
                        title: 'recentSales'.tr,
                        trailing: TextButton(
                          onPressed: () => Get.toNamed('/sale-history'),
                          child: Text('viewAll'.tr),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (controller.recentSales.isEmpty)
                        DashboardEmptyState(
                          text: 'noSalesRecordedYet'.tr,
                          icon: Icons.point_of_sale_rounded,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.recentSales.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final sale = controller.recentSales[index];
                            return RecentSaleTile(
                              productName: sale.productName,
                              subtitle: '${sale.quantity} ${'unitsSold'.tr}',
                              amount: controller.formatCurrency(sale.total),
                              date: sale.date,
                            );
                          },
                        ).animate().fadeIn(delay: 350.ms, duration: 300.ms),

                      const SizedBox(height: 28),

                      DashboardSectionHeader(
                        title: 'recentPurchases'.tr,
                        trailing: TextButton(
                          onPressed: () => Get.toNamed('/purchases'),
                          child: Text('viewAll'.tr),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (controller.recentPurchases.isEmpty)
                        DashboardEmptyState(
                          text: 'noPurchasesRecordedYet'.tr,
                          icon: Icons.shopping_bag_outlined,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.recentPurchases.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final purchase = controller.recentPurchases[index];
                            return RecentPurchaseTile(
                              productName: purchase.productName,
                              subtitle: '${purchase.quantity} ${'unitsRestocked'.tr}',
                              amount:
                              controller.formatCurrency(purchase.total),
                              date: purchase.date,
                            );
                          },
                        ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, ColorScheme scheme, bool isDark) {
    return Row(
      children: [
        _buildActionButton(
          context,
          icon: Icons.add_shopping_cart_rounded,
          label: 'newSale'.tr,
          color: const Color(0xFF10B981),
          onTap: () => Get.toNamed('/sales'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          icon: Icons.add_box_rounded,
          label: 'addStock'.tr,
          color: scheme.primary,
          onTap: () => Get.toNamed('/add-product'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          icon: Icons.shopping_bag_outlined,
          label: 'orders'.tr,
          color: const Color(0xFF8B5CF6),
          onTap: () => Get.toNamed('/orders'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          icon: Icons.receipt_long_rounded,
          label: 'debts'.tr,
          color: const Color(0xFFF97316),
          onTap: () => Get.toNamed('/debts'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreMeshHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _StoreMeshHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final meshGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
        HSLColor.fromColor(secondaryColor).withLightness(isDark ? 0.14 : 0.30).toColor(),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = meshGradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.88, height * 0.10), 130, Colors.white, 0.14, 70);
    glassOrb(Offset(width * 0.15, height * 0.85), 100, secondaryColor, 0.30, 60);
    glassOrb(Offset(width * 0.55, height * 0.05), 70, Colors.white, 0.10, 40);

    final sheenPath = Path()
      ..moveTo(width * 0.35, -20)
      ..lineTo(width * 0.55, -20)
      ..lineTo(width * 0.05, height + 20)
      ..lineTo(width * -0.15, height + 20)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect),
    );

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34, ringPaint);
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34 * 1.5, ringPaint..color = Colors.white.withOpacity(0.08));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _StoreMeshHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}