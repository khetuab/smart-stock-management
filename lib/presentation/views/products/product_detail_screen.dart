import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(productData.name),
        backgroundColor: Color(
          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              controller.editProduct(productData);
              Get.toNamed('/add-product');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => controller.deleteProduct(productData),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image: productData.image.isNotEmpty
                    ? DecorationImage(
                  image: NetworkImage(productData.image),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: productData.image.isEmpty
                  ? Icon(
                Icons.inventory_2,
                size: 80,
                color: Colors.grey.shade400,
              )
                  : null,
            ),

            const SizedBox(height: 24),

            // Product Name
            Text(
              productData.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

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
        ),
      ),
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