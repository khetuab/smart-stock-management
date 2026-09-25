import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../../widgets/order_via_telegram_sheet.dart';
import '../orders/create_order_screen.dart';

/// The full product catalog, customer-facing only. No add/edit/delete
/// affordances anywhere — browsing and ordering only.
class CustomerAllProductsScreen extends GetView<ProductController> {
  const CustomerAllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = Get.find<DashboardController>();

    return Scaffold(
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () => controller.loadProducts(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
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
                title: Text(
                  'All Products'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _CatalogHeaderPainter(primaryColor: scheme.primary, secondaryColor: scheme.tertiary, isDark: isDark),
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
                      child: Obx(() => Text(
                        '${controller.filteredProducts.length} ${'items available'.tr}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      )),
                    ),
                  ],
                ),
              ),

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = products[index];
                      return _OrderableProductCard(
                        product: product,
                        formatCurrency: dashboard.formatCurrency,
                        onOrder: () => Get.to(() => CreateOrderScreen(initialProduct: product)),
                      ).animate().fadeIn(delay: (25 * index).ms, duration: 250.ms);
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

class _OrderableProductCard extends StatelessWidget {
  final Product product;
  final String Function(double) formatCurrency;
  final VoidCallback onOrder;

  const _OrderableProductCard({
    required this.product,
    required this.formatCurrency,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inStock = product.quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : scheme.shadow.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Image ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 1.15,
                  child: product.image.isNotEmpty
                      ? Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
                    ),
                  )
                      : Container(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.inventory_2_outlined, size: 36, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              if (!inStock)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      color: Colors.black45,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: scheme.error, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        'Out of Stock'.tr,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // --- Info ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category.isEmpty ? 'General'.tr : product.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(product.sellingPrice),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: scheme.primary, letterSpacing: -0.3),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton.icon(
                    onPressed: inStock ? () => OrderViaTelegramSheet.show(context, product) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      disabledBackgroundColor: scheme.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.shopping_bag_outlined, size: 15,
                        color: inStock ? Colors.white : scheme.onSurfaceVariant),
                    label: Text(
                      'Order'.tr,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                          color: inStock ? Colors.white : scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Same glass-mesh visual language as the rest of the app's headers.
class _CatalogHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _CatalogHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }
    glassOrb(Offset(width * 0.85, height * 0.15), 90, Colors.white, 0.14, 50);
    glassOrb(Offset(width * 0.12, height * 0.8), 70, secondaryColor, 0.28, 45);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
          stops: const [0.45, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CatalogHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
}