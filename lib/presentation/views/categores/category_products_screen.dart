import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/product_card.dart';

/// Products filtered to a single category with a sleek inline search bar.
class CategoryProductsScreen extends GetView<ProductController> {
  final Category category;
  final RxBool isSearching = false.obs;

  CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categoryColor = category.color != null
        ? AppTheme.colorFromHex(category.color!)
        : scheme.primary;

    return PopScope(
      canPop: !isSearching.value,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSearching.value) {
          isSearching.value = false;
          controller.searchQuery.value = '';
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Obx(() {
            if (isSearching.value) {
              return IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  isSearching.value = false;
                  controller.searchQuery.value = '';
                },
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                controller.searchQuery.value = '';
                Get.back();
              },
            );
          }),
          title: Obx(() {
            if (isSearching.value) {
              return TextField(
                autofocus: true,
                style: TextStyle(color: scheme.onSurface, fontSize: 16),
                decoration: InputDecoration(
                  hintText: '${'searchIn'.tr} ${category.name}...',
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: (value) => controller.searchQuery.value = value,
              );
            }
            return Row(
              children: [
                Text(category.icon ?? '📦', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          }),
          actions: [
            Obx(() {
              if (isSearching.value) {
                return controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    controller.searchQuery.value = '';
                  },
                )
                    : const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => isSearching.value = true,
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter by Category
          final categoryProducts = controller.products
              .where((p) => p.category.toLowerCase() == category.name.toLowerCase())
              .toList();

          // Filter by Search Term
          final query = controller.searchQuery.value.toLowerCase().trim();
          final filteredProducts = query.isNotEmpty
              ? categoryProducts.where((p) =>
          p.name.toLowerCase().contains(query) ||
              p.barcode.toLowerCase().contains(query)).toList()
              : categoryProducts;

          if (filteredProducts.isEmpty) {
            return AppEmptyState(
              icon: query.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              title: query.isNotEmpty
                  ? 'noResultsFound'.tr
                  : '${'noProductsIn'.tr} "${category.name}"',
              subtitle: query.isNotEmpty
                  ? 'tryDifferentKeyword'.tr
                  : 'addProductsToCategory'.tr,
              actionLabel: query.isNotEmpty ? null : 'addProduct'.tr,
              onAction: query.isNotEmpty
                  ? null
                  : () {
                controller.searchQuery.value = '';
                Get.back();
                Get.toNamed('/add-product');
              },
            );
          }

          return Column(
            children: [
              // Search Results Count Bar
              if (query.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: categoryColor.withOpacity(0.08),
                  child: Text(
                    '${filteredProducts.length} ${'productsFound'.tr}',
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Product Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.loadProducts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onEdit: () {
                          controller.editProduct(product);
                          Get.toNamed('/add-product');
                        },
                        onDelete: () => controller.deleteProduct(product),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}