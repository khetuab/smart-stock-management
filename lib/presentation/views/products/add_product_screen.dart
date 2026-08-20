import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
                  controller.setImage(imageUrl);
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
                  controller.setImage(imageUrl);
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
              // --- Image Upload Box ---
              GestureDetector(
                onTap: () => _showImagePickerOptions(context, scheme),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? scheme.surfaceContainerHigh
                        : scheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    image: controller.productImage.value.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(controller.productImage.value),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: controller.productImage.value.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'tapToUploadPhoto'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                      : Stack(
                    children: [
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'change'.tr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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