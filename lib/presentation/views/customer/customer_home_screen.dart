import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/widgets/social_media_row.dart';
import '../../../app/routes/app_routes.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../../widgets/customer_drawer.dart';
import '../../widgets/customer_product_card.dart';
import '../../widgets/promotion_banner_carousel.dart';
import '../../widgets/secret_owner_access.dart';
import '../../widgets/social_media_rail.dart';
import '../orders/create_order_screen.dart';

/// The customer's entire world starts here: a browse-only shop-front.
/// No add/edit/delete affordances anywhere on this screen — that's the
/// whole point of it existing separately from ProductListScreen.
class CustomerHomeScreen extends GetView<ProductController> {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 0),
      body:
            RefreshIndicator(
              onRefresh: () => controller.loadProducts(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    leading: Obx(
                          () => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SecretOwnerAccess(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                              image: dashboard.storeLogo.value.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(dashboard.storeLogo.value), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: dashboard.storeLogo.value.isEmpty
                                ? const Icon(Icons.storefront_rounded, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    expandedHeight: 190,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 4,
                    surfaceTintColor: scheme.surface,
                    backgroundColor: scheme.primary,
                    iconTheme: const IconThemeData(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                      title: Obx(
                            () => Text(
                          dashboard.storeName.value.isEmpty ? 'Our Shop'.tr : dashboard.storeName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(
                            painter: _ShopHeaderPainter(primaryColor: scheme.primary, secondaryColor: scheme.tertiary, isDark: isDark),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withOpacity(0.15), Colors.transparent, Colors.black.withOpacity(0.35)],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 50,
                            child: Text(
                              'Browse our latest products and place an order in seconds.'.tr,
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(onPressed: (){
                        Get.toNamed(AppRoutes.customerSettings);
                      }, icon: Icon(Icons.settings))
                    ],

                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: controller.searchProducts,
                        decoration: InputDecoration(
                          hintText: 'searchProducts'.tr,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHighest.withOpacity(0.5),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: PromotionBannerCarousel()),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 42,
                      child: Obx(() {
                        final categories = controller.categories.toList();
                        final selected = controller.selectedCategory.value;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = category == selected;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (_) => controller.filterByCategory(category),
                                selectedColor: scheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : scheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  Obx(() {
                    if (controller.isLoading.value) {
                      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive()));
                    }

                    final products = controller.filteredProducts;
                    if (products.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No products available'.tr,
                          subtitle: 'Check back soon — new items are added regularly.'.tr,
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final product = products[index];
                            return CustomerProductCard(
                              product: product,
                            ).animate().fadeIn(delay: (30 * index).ms, duration: 250.ms);
                          },
                          childCount: products.length,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

/// Same glass-mesh visual language as the rest of the app's headers,
/// themed toward "storefront" rather than "back office".
class _ShopHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _ShopHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});

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
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }

    glassOrb(Offset(width * 0.88, height * 0.10), 120, Colors.white, 0.14, 65);
    glassOrb(Offset(width * 0.12, height * 0.85), 90, secondaryColor, 0.28, 55);

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
  bool shouldRepaint(covariant _ShopHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
}