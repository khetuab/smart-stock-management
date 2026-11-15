import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/category_model.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/category_controller.dart';
import '../../controllers/dashboard_controller.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late final ProductController controller;
  late final CategoryController categoryController;
  late final DashboardController dashboardController;

  late final TextEditingController nameController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController sellingPriceController;
  late final TextEditingController quantityController;
  late final TextEditingController minQuantityController;
  late final TextEditingController barcodeController;
  late final TextEditingController descriptionController;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductController>();
    categoryController = Get.find<CategoryController>();
    dashboardController = Get.find<DashboardController>();

    nameController = TextEditingController(text: controller.productName.value);
    _selectedCategory = controller.productCategory.value.isNotEmpty
        ? controller.productCategory.value
        : null;
    purchasePriceController = TextEditingController(
      text: controller.purchasePrice.value > 0
          ? controller.purchasePrice.value.toString()
          : '',
    );
    sellingPriceController = TextEditingController(
      text: controller.sellingPrice.value > 0
          ? controller.sellingPrice.value.toString()
          : '',
    );
    quantityController = TextEditingController(
      text: controller.quantity.value > 0
          ? controller.quantity.value.toString()
          : '',
    );
    minQuantityController = TextEditingController(
      text: controller.minQuantity.value > 0
          ? controller.minQuantity.value.toString()
          : '',
    );
    barcodeController = TextEditingController(text: controller.barcode.value);
    descriptionController = TextEditingController(text: controller.description.value);

    if (categoryController.categories.isEmpty) {
      categoryController.loadCategories();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    quantityController.dispose();
    minQuantityController.dispose();
    barcodeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions(BuildContext context, ColorScheme scheme) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'selectImageSource'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'photosCanBeAdded'.tr,
              style: TextStyle(
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withOpacity(0.1),
                child: Icon(Icons.camera_alt_outlined, color: scheme.primary),
              ),
              title: Text(
                'camera'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('takePhotoWithCamera'.tr),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () async {
                Get.back();
                final imageUrl = await CloudinaryService().uploadFromCamera(
                  folder: 'products',
                  isPublic: true,
                );
                if (imageUrl != null) {
                  controller.addProductImage(imageUrl);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withOpacity(0.1),
                child: Icon(Icons.photo_library_outlined, color: scheme.primary),
              ),
              title: Text(
                'gallery'.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('chooseFromGallery'.tr),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () async {
                Get.back();
                final imageUrl = await CloudinaryService().uploadFromGallery(
                  folder: 'products',
                  isPublic: true,
                );
                if (imageUrl != null) {
                  controller.addProductImage(imageUrl);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = controller.isEditing.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'editProduct'.tr : 'addProduct'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              tooltip: 'deleteProduct'.tr,
              onPressed: () => _confirmDelete(context, scheme),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Multi-Photo Gallery ---
              _MultiPhotoGallery(
                controller: controller,
                isDark: isDark,
                scheme: scheme,
                onAddPhoto: () => _showImagePickerOptions(context, scheme),
              ),

              const SizedBox(height: 24),

              // --- Primary Details Section ---
              _buildSectionTitle('basicInformation'.tr, scheme),
              const SizedBox(height: 12),

              // Product Name
              _buildFormTextField(
                controller: nameController,
                label: 'productNameRequired'.tr,
                icon: Icons.shopping_bag_outlined,
                errorText: controller.nameError.value.isEmpty
                    ? null
                    : controller.nameError.value,
                onChanged: (value) => controller.productName.value = value,
                isDark: isDark,
                scheme: scheme,
              ),

              const SizedBox(height: 14),

              // Category Picker Dropdown
              Obx(() {
                if (categoryController.isLoading.value) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }

                final categoryOptions = <String>[];
                categoryOptions.addAll(
                  categoryController.categories.map((c) => c.name).toList(),
                );
                categoryOptions.add('+ ${'addNewCategory'.tr}');

                if (_selectedCategory != null &&
                    !categoryOptions.contains(_selectedCategory)) {
                  _selectedCategory = null;
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    labelText: 'categoryRequired'.tr,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? scheme.surfaceContainerHigh
                        : scheme.surfaceContainerHighest.withOpacity(0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorText: controller.categoryError.value.isEmpty
                        ? null
                        : controller.categoryError.value,
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      size: 20,
                      color: scheme.primary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  items: categoryOptions.map((category) {
                    final isAddNew = category == '+ ${'addNewCategory'.tr}';
                    final catObj = categoryController.categories.firstWhere(
                          (c) => c.name == category,
                      orElse: () => Category(name: ''),
                    );

                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          if (!isAddNew) ...[
                            Text(catObj.icon ?? '📦',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.add_circle_outline_rounded,
                                color: scheme.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              category,
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == '+ ${'addNewCategory'.tr}') {
                      Get.toNamed('/add-category')?.then((_) {
                        categoryController.loadCategories();
                        setState(() {
                          _selectedCategory = controller.productCategory.value;
                        });
                      });
                      return;
                    }

                    setState(() {
                      _selectedCategory = value;
                    });
                    controller.productCategory.value = value ?? '';
                    controller.categoryError.value = '';
                  },
                );
              }),

              const SizedBox(height: 24),

              // --- Pricing & Stock Section ---
              _buildSectionTitle('pricingAndInventory'.tr, scheme),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildFormTextField(
                      controller: purchasePriceController,
                      label: 'costPriceRequired'.tr,
                      icon: Icons.arrow_downward_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      errorText: controller.purchasePriceError.value.isEmpty
                          ? null
                          : controller.purchasePriceError.value,
                      onChanged: (value) {
                        controller.purchasePrice.value =
                            double.tryParse(value) ?? 0.0;
                      },
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormTextField(
                      controller: sellingPriceController,
                      label: 'sellingPriceRequired'.tr,
                      icon: Icons.arrow_upward_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      errorText: controller.sellingPriceError.value.isEmpty
                          ? null
                          : controller.sellingPriceError.value,
                      onChanged: (value) {
                        controller.sellingPrice.value =
                            double.tryParse(value) ?? 0.0;
                      },
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _buildFormTextField(
                      controller: quantityController,
                      label: 'inStockQtyRequired'.tr,
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      errorText: controller.quantityError.value.isEmpty
                          ? null
                          : controller.quantityError.value,
                      onChanged: (value) {
                        controller.quantity.value =
                            double.tryParse(value) ?? 0.0;
                      },
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormTextField(
                      controller: minQuantityController,
                      label: 'minLowAlertRequired'.tr,
                      icon: Icons.warning_amber_rounded,
                      keyboardType: TextInputType.number,
                      errorText: controller.minQuantityError.value.isEmpty
                          ? null
                          : controller.minQuantityError.value,
                      onChanged: (value) {
                        controller.minQuantity.value =
                            double.tryParse(value) ?? 0.0;
                      },
                      isDark: isDark,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Optional Information Section ---
              _buildSectionTitle('additionalDetails'.tr, scheme),
              const SizedBox(height: 12),

              _buildFormTextField(
                controller: barcodeController,
                label: 'barcodeOptional'.tr,
                icon: Icons.qr_code_scanner_rounded,
                onChanged: (value) => controller.barcode.value = value,
                isDark: isDark,
                scheme: scheme,
              ),

              const SizedBox(height: 14),

              _buildFormTextField(
                controller: descriptionController,
                label: 'descriptionOptional'.tr,
                icon: Icons.notes_rounded,
                maxLines: 3,
                onChanged: (value) => controller.description.value = value,
                isDark: isDark,
                scheme: scheme,
              ),

              const SizedBox(height: 28),

              // --- Submit Action Button ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    if (isEditing) {
                      controller.updateProduct();
                    } else {
                      controller.addProduct();
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    isEditing ? Icons.save_rounded : Icons.add_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isEditing ? 'saveChanges'.tr : 'createProduct'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Category Manager Quick Navigation Tile ---
              InkWell(
                onTap: () => Get.toNamed('/categories'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHigh
                        : scheme.surfaceContainerHighest.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_suggest_outlined,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'manageCategoriesList'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme scheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required bool isDark,
    required ColorScheme scheme,
    TextInputType? keyboardType,
    String? errorText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerHighest.withOpacity(0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorText: errorText,
        prefixIcon: Icon(icon, size: 20, color: scheme.primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: onChanged,
    );
  }

  void _confirmDelete(BuildContext context, ColorScheme scheme) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('deleteProduct'.tr),
        content: Text('deleteProductConfirmDesc'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Get.back();
              if (controller.selectedProduct.value != null) {
                controller.deleteProduct(controller.selectedProduct.value!);
              }
            },
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }
}
/// ─────────────────────────────────────────────────────────────────────────
///  Multi-photo gallery for the product form.
///  • Horizontal strip of uploaded photos (first = cover, tagged "Main").
///  • "+ Add Photo" tile opens the camera/gallery picker (multiple adds).
///  • Per-photo: remove (x) and "make main" (star) controls.
///  • Photos are joined with '|' into the existing single `image` cell —
///    zero changes to the Products sheet schema.
/// ─────────────────────────────────────────────────────────────────────────
class _MultiPhotoGallery extends StatelessWidget {
  final ProductController controller;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onAddPhoto;

  const _MultiPhotoGallery({
    required this.controller,
    required this.isDark,
    required this.scheme,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_rounded, size: 16, color: MejlisPalette.goldDark),
            const SizedBox(width: 6),
            Text(
              'productPhotos'.tr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Obx(() {
            final images = controller.productImages;
            final showAddTile = images.length < 10;

            return ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                for (int i = 0; i < images.length; i++)
                  _PhotoThumb(
                    url: images[i],
                    isMain: i == 0,
                    onRemove: () => controller.removeProductImage(i),
                    onSetMain: i == 0 ? null : () => controller.setMainProductImage(i),
                  ),
                if (showAddTile)
                  _AddPhotoTile(
                    isDark: isDark,
                    scheme: scheme,
                    onTap: onAddPhoto,
                    count: images.length,
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final bool isMain;
  final VoidCallback onRemove;
  final VoidCallback? onSetMain;

  const _PhotoThumb({
    required this.url,
    required this.isMain,
    required this.onRemove,
    this.onSetMain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_rounded),
              ),
            ),
            // Gradient + main tag
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  ),
                ),
              ),
            ),
            if (isMain)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: MejlisPalette.goldGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'mainPhoto'.tr,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A2104),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 6,
                bottom: 6,
                child: GestureDetector(
                  onTap: onSetMain,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: MejlisPalette.goldLight),
                        const SizedBox(width: 3),
                        Text(
                          'makeMain'.tr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Remove button
            Positioned(
              right: 4,
              top: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onTap;
  final int count;

  const _AddPhotoTile({
    required this.isDark,
    required this.scheme,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MejlisPalette.gold.withOpacity(0.6),
            width: 1.6,
          ),
          color: isDark
              ? scheme.surfaceContainerHigh
              : scheme.surfaceContainerHighest.withOpacity(0.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: MejlisPalette.goldGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                size: 22,
                color: Color(0xFF2A2104),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'addPhoto'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '$count/10',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
