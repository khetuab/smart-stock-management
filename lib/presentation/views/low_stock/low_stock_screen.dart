import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class LowStockScreen extends GetView<ProductController> {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('lowStockItems'.tr),
        backgroundColor: Color(
          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
        ),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowStockItems = controller.products
            .where((p) => p.quantity <= p.minQuantity)
            .toList();

        if (lowStockItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'allProductsWellStocked'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'noLowStockItems'.tr,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lowStockItems.length,
          itemBuilder: (context, index) {
            final product = lowStockItems[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${'categoryLabel'.tr}: ${product.category}'),
                    Text(
                      '${'currentLabel'.tr}: ${product.quantity} / ${'minimumLabel'.tr}: ${product.minQuantity}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dashboardController.formatCurrency(product.sellingPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${'stockLabel'.tr}: ${product.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // onTap: () {
                //   Get.toNamed('/add-product', arguments: product);
                // },
              ),
            );
          },
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}