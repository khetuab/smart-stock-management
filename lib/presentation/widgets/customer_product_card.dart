import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/themes/app_theme.dart';
import '../../data/models/product_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../views/auth/customer_welcome_screen.dart';
import '../views/orders/create_order_screen.dart';
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
            onTap: () => showQuickView(context, product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.15,
                      child: ProductImageCarousel(images: product.images),
                    ),
                    // Gradient (ignores touches so swipes pass through to the carousel)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 56,
                      child: IgnorePointer(
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
                    ),
                    // Stock badge
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: outOfStock
                                ? scheme.error.withOpacity(0.92)
                                : Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            outOfStock ? 'Out of stock'.tr : 'In stock'.tr,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
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

  // after
  static void showQuickView(BuildContext context, Product product) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final outOfStock = product.quantity <= 0;
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.92),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                const SizedBox(height: 16),

                // Gallery (main image + thumbnails)
                ProductGallery(images: product.images, height: 260),

                const SizedBox(height: 18),
                Text(
                  product.name,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onSurface),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.category.isEmpty ? 'General'.tr : product.category,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        dashboardController.formatCurrency(product.sellingPrice),
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary),
                      ),
                    ),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (outOfStock ? scheme.error : Colors.green)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        outOfStock ? 'Out of stock'.tr : 'In stock'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: outOfStock ? scheme.error : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (product.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    product.description,
                    style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: outOfStock
                        ? null
                        : () {
                      Get.back();
                      final auth = Get.find<AuthController>();
                      if (!auth.isLoggedIn.value) {
                        Get.to(() => const CustomerWelcomeScreen());
                        return;
                      }
                      Get.to(() => CreateOrderScreen(initialProduct: product));
                    },
                    icon: const Icon(Icons.shopping_bag_rounded),
                    label: Text(outOfStock ? 'Out of stock'.tr : 'Place an Order'.tr),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }


}

/// Swipeable photo gallery. Falls back to a single image when the
/// product has 0 or 1 photos.
class ProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final double borderRadius;

  const ProductImageCarousel({
    super.key,
    required this.images,
    this.height = double.infinity,
    this.borderRadius = 0,
  });

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.length <= 1) {
      return ProductImageBox(
        imageUrl: images.isEmpty ? '' : images.first,
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => ProductImageBox(
            imageUrl: images[i],
            height: double.infinity,
            borderRadius: widget.borderRadius,
          ),
        ),
        // Page dots (bottom-right, so they don't overlap the stock badge)
        Positioned(
          right: 10,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: active ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

/// Large gallery for the quick-view sheet: swipe, arrows, counter, thumbnails.
class ProductGallery extends StatefulWidget {
  final List<String> images;
  final double height;

  const ProductGallery({super.key, required this.images, this.height = 260});

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = widget.images;

    if (images.length <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ProductImageBox(
          imageUrl: images.isEmpty ? '' : images.first,
          height: widget.height,
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => ProductImageBox(
                    imageUrl: images[i],
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                ),
                // Counter
                Positioned(
                  top: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                // Previous / next arrows
                if (_index > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _arrow(Icons.chevron_left_rounded,
                              () => _goTo(_index - 1)),
                    ),
                  ),
                if (_index < images.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _arrow(Icons.chevron_right_rounded,
                              () => _goTo(_index + 1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Thumbnails
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final active = i == _index;
              return GestureDetector(
                onTap: () => _goTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? scheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Opacity(
                    opacity: active ? 1 : 0.6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: ProductImageBox(
                        imageUrl: images[i],
                        height: double.infinity,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}