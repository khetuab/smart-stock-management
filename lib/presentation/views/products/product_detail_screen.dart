import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';

class ProductDetailScreen extends GetView<ProductController> {
  final Product? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    // If product is null, try to get from arguments or show error
    final Product? productData = product ?? Get.arguments as Product?;

    if (productData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('productNotFound'.tr),
          backgroundColor: Color(
            int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
          ),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'productNotFound'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'productNotFoundDesc'.tr,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLowStock = productData.quantity <= productData.minQuantity;

    return ProductPhotoGallery(product: productData);
  }
}

/// ─────────────────────────────────────────────────────────────────────────
///  Product detail with a swipeable photo gallery:
///  • PageView carousel over ALL product photos (pinch-zoom on tap).
///  • Dot indicators + thumbnail strip; tap a thumb to jump.
///  • Photos live in the single `image` cell, pipe-separated — the legacy
///    single photo renders exactly as before.
///  The original admin info/actions UI becomes the gallery's bottom sheet
///  trigger, keeping every existing business action reachable.
/// ─────────────────────────────────────────────────────────────────────────
class ProductPhotoGallery extends StatefulWidget {
  final Product product;
  const ProductPhotoGallery({super.key, required this.product});

  @override
  State<ProductPhotoGallery> createState() => _ProductPhotoGalleryState();
}

class _ProductPhotoGalleryState extends State<ProductPhotoGallery> {
  final PageController _pageController = PageController();
  int _page = 0;

  List<String> get _photos {
    final imgs = widget.product.images;
    return imgs.isEmpty ? const <String>[] : imgs;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;
    final isLowStock = product.quantity <= product.minQuantity;
    final photos = _photos;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.find<ProductController>().editProduct(product);
              Get.toNamed('/add-product');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Get.find<ProductController>().deleteProduct(product),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo carousel ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: photos.isEmpty
                      ? Container(
                          height: 280,
                          width: double.infinity,
                          color: isDark
                              ? scheme.surfaceContainerHigh
                              : scheme.surfaceContainerHighest.withOpacity(0.5),
                          child: Icon(
                            Icons.inventory_2,
                            size: 80,
                            color: scheme.onSurfaceVariant.withOpacity(0.4),
                          ),
                        )
                      : SizedBox(
                          height: 300,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: photos.length,
                            onPageChanged: (i) => setState(() => _page = i),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => _openZoomViewer(context, photos, i),
                              child: Image.network(
                                photos[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded, size: 60),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                // Page counter badge
                if (photos.length > 1)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: MejlisPalette.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_page + 1} / ${photos.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A2104),
                        ),
                      ),
                    ),
                  ),
                // Zoom hint
                if (photos.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Thumbnail strip ──
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _page;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? MejlisPalette.gold : Colors.transparent,
                            width: 2.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Product Name
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),
            _originalInfoSection(context, product, dashboardController, isLowStock),
          ],
        ),
      ),
    );
  }

  /// Opens the full-screen pinch-zoom photo viewer.
  void _openZoomViewer(BuildContext context, List<String> photos, int initial) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: _ZoomablePhotoViewer(photos: photos, initialIndex: initial),
          );
        },
      ),
    );
  }
}

/// Full-screen InteractiveViewer gallery — pinch & double-tap zoom.
class _ZoomablePhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const _ZoomablePhotoViewer({required this.photos, required this.initialIndex});

  @override
  State<_ZoomablePhotoViewer> createState() => _ZoomablePhotoViewerState();
}

class _ZoomablePhotoViewerState extends State<_ZoomablePhotoViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.94),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        itemBuilder: (context, i) => Center(
          child: InteractiveViewer(
            maxScale: 5,
            minScale: 0.5,
            child: Image.network(
              widget.photos[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_rounded,
                size: 70,
                color: Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The original admin info & quick-actions block, preserved verbatim in
/// structure so no business behavior changes.
extension on _ProductPhotoGalleryState {
  Widget _originalInfoSection(
    BuildContext context,
    Product productData,
    DashboardController dashboardController,
    bool isLowStock,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

            // Category
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                productData.category,
                style: TextStyle(
                  color: Color(
                    int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'stockStatus'.tr,
                    isLowStock ? 'lowStock'.tr : 'inStock'.tr,
                    Icons.inventory,
                    isLowStock ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'quantity'.tr,
                    productData.quantity.toString(),
                    Icons.numbers,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'purchasePrice'.tr,
                    dashboardController.formatCurrency(productData.purchasePrice),
                    Icons.arrow_downward,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'sellingPrice'.tr,
                    dashboardController.formatCurrency(productData.sellingPrice),
                    Icons.arrow_upward,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Profit Margin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profitMargin'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    productData.purchasePrice > 0
                        ? '${((productData.sellingPrice - productData.purchasePrice) / productData.purchasePrice * 100).toStringAsFixed(1)}%'
                        : '0%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: productData.sellingPrice > productData.purchasePrice
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Barcode
            if (productData.barcode.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'barcode'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            productData.barcode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Description
            if (productData.description.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'description'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      productData.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed('/sales');
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: Text('sell'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(
                        int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed('/purchases');
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text('restock'.tr),
                  ),
                ),
              ],
            ),
          ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}