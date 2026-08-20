import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/themes/app_theme.dart';
import '../../controllers/category_controller.dart';

/// Add/Edit Category — rewritten to drop manual theme-color hex parsing
/// for the AppBar/submit button (now inherited from the app theme via
/// `AppBarTheme`/`ElevatedButtonTheme`) while keeping `AppTheme.colorFromHex`
/// for the per-category swatch, since that color is user-chosen category
/// data, not the app's brand color.
class AddCategoryScreen extends GetView<CategoryController> {
  const AddCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = controller.isEditing.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'editCategory'.tr : 'addCategory'.tr),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () {
                if (controller.selectedCategory.value != null) {
                  controller.deleteCategory(controller.selectedCategory.value!);
                }
              },
              child: Text('delete'.tr, style: TextStyle(color: scheme.error)),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final swatchColor = AppTheme.colorFromHex(controller.categoryColor.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon preview
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: swatchColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: swatchColor, width: 2),
                      ),
                      child: Center(
                        child: Text(controller.categoryIcon.value, style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('selectedIcon'.tr, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              TextField(
                controller: controller.nameController,
                onChanged: (val) => controller.categoryName.value = val,
                decoration: InputDecoration(
                  labelText: 'categoryNameRequired'.tr,
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: controller.descriptionController,
                onChanged: (val) => controller.categoryDescription.value = val,
                decoration: InputDecoration(
                  labelText: 'descriptionOptional'.tr,
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              Text('selectIcon'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.availableIcons.map((icon) {
                  final isSelected = controller.categoryIcon.value == icon;
                  return GestureDetector(
                    onTap: () => controller.setIcon(icon),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected ? swatchColor : Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? swatchColor : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Text('selectColor'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.availableColors.map((colorHex) {
                  final color = AppTheme.colorFromHex(colorHex);
                  final isSelected = controller.categoryColor.value == colorHex;
                  return GestureDetector(
                    onTap: () => controller.setColor(colorHex),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: scheme.onSurface, width: 3) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isEditing ? controller.updateCategory : controller.addCategory,
                  child: Text(isEditing ? 'updateCategory'.tr : 'addCategory'.tr),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}