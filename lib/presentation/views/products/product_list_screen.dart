import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/product_controller.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends GetView<ProductController> {
  const ProductListScreen({super.key});

  Color _parseColor(String hexColor, {Color fallback = Colors.blue}) {
    try {
      final cleanHex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: AppBar(

          title: Text('products'.tr),
          actions: [
            // In ProductListScreen actions (AppBar Add Button)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                controller.clearForm();
                await Get.toNamed('/add-product');
                controller.loadProducts(); // Auto-refresh when returning
              },
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1. Constrain TextField horizontally & vertically
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'searchProducts'.tr,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: controller.searchProducts,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Read reactive variables directly inside Obx builder scope
                      Obx(() {
                        final categoryList = controller.categories.toList();
                        final currentSelected = controller.selectedCategory.value;

                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list ),
                          onSelected: controller.filterByCategory,
                          itemBuilder: (context) {
                            return categoryList.map((category) {
                              return PopupMenuItem<String>(
                                value: category,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (currentSelected == category)
                                      const Icon(Icons.check, size: 16)
                                    else
                                      const SizedBox(width: 16),
                                    const SizedBox(width: 8),
                                    Text(category),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'noProductsFound'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'tapPlusOrPullToRefresh'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => controller.loadProducts(),
                  icon: const Icon(Icons.refresh),
                  label: Text('retryConnection'.tr),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadProducts(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = controller.filteredProducts[index];
              return ProductCard(
                product: product,
                // In ProductCard edit callback
                onEdit: () async {
                  controller.editProduct(product);
                  await Get.toNamed('/add-product');
                  controller.loadProducts(); // Auto-refresh after editing
                },
                onDelete: () => controller.deleteProduct(product),
              );
            },
          ),
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}