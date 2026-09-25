import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../controllers/dashboard_controller.dart';
import 'app_kits_collection.dart';
import 'order_via_telegram_sheet.dart';

/// Same visual language as the admin ProductCard, but strictly read-only:
/// no edit, no delete, no stock-management actions. Tapping a card opens
/// a quick-view sheet with an "Order This" call to action.
class CustomerProductCard extends StatelessWidget {
  final Product product;
  //final ValueChanged<Product> onOrder;

  const CustomerProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final outOfStock = product.quantity <= 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : scheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showQuickView(context, dashboardController),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.15,
                      child: ProductImageBox(
                        imageUrl: product.image,
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: outOfStock ? scheme.error.withOpacity(0.92) : Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          outOfStock ? 'Out of stock'.tr : 'In stock'.tr,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: scheme.onSurface),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.category.isEmpty ? 'General'.tr : product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dashboardController.formatCurrency(product.sellingPrice),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: scheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickView(BuildContext context, DashboardController dashboardController) {
    final scheme = Theme.of(context).colorScheme;
    final outOfStock = product.quantity <= 0;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProductImageBox(imageUrl: product.image, height: 160),
              ),
              const SizedBox(height: 16),
              Text(product.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: scheme.onSurface)),
              const SizedBox(height: 4),
              Text(
                product.category.isEmpty ? 'General'.tr : product.category,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                dashboardController.formatCurrency(product.sellingPrice),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: scheme.primary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: outOfStock ? null : () {
                    Get.back();
                    OrderViaTelegramSheet.show(context, product);
                  },
                  icon: const Icon(Icons.shopping_bag_rounded),
                  label: Text(outOfStock ? 'Out of stock'.tr : 'Place an Order'.tr),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}