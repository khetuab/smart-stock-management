import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/category_model.dart';
import '../../data/services/google_sheets_service.dart';

class CategoryController extends GetxController {
  final GoogleSheetsService _sheets = GoogleSheetsService();

  // Initialize directly to prevent LateInitializationError
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  var categories = <Category>[].obs;
  var isLoading = false.obs;

  // Form fields
  var categoryName = ''.obs;
  var categoryDescription = ''.obs;
  var categoryIcon = '📦'.obs;
  var categoryColor = '#2196F3'.obs;
  var isEditing = false.obs;
  var selectedCategory = Rxn<Category>();

  // Predefined icons
  final List<String> availableIcons = [
    '📱', '👕', '🍔', '💊', '🔧', '📚', '🏠',
    '⚡', '🎮', '🍕', '💻', '📷', '🚗',
    '✏️', '🛒', '🏷️', '📦', '🎯', '⭐', '🔥', '💎',
  ];

  // Predefined colors
  final List<String> availableColors = [
    '#2196F3', '#4CAF50', '#FF5722', '#9C27B0',
    '#E91E63', '#00BCD4', '#FF9800', '#8BC34A',
    '#FF6B6B', '#2ECC71', '#3498DB', '#F39C12',
    '#1ABC9C', '#E74C3C', '#2980B9', '#27AE60',
  ];

  static CategoryController get to {
    if (Get.isRegistered<CategoryController>()) {
      return Get.find<CategoryController>();
    }
    return Get.put(CategoryController(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();

    nameController.addListener(() {
      categoryName.value = nameController.text;
    });

    descriptionController.addListener(() {
      categoryDescription.value = descriptionController.text;
    });

    loadCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Categories');

      // 1. Fetch data from "Categories" sheet
      final categoriesData = await _sheets.getSheetDataWithHeaders('Categories');

      List<Category> categoryList = [];

      if (categoriesData.isNotEmpty) {
        // Parse categories saved in the "Categories" sheet
        categoryList = _parseCategories(categoriesData);
      }

      // 2. Fetch "Products" sheet to calculate product count for each category
      final productData = await _sheets.getSheetDataWithHeaders('Products');
      final productCategories = productData['category'] ?? [];

      // Map counts by lowercased category name
      final Map<String, int> categoryCounts = {};
      for (var cat in productCategories) {
        final categoryName = cat?.toString().trim() ?? '';
        if (categoryName.isNotEmpty) {
          final key = categoryName.toLowerCase();
          categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
        }
      }

      // 3. Attach product counts to each category object
      final updatedList = categoryList.map((category) {
        final count = categoryCounts[category.name.trim().toLowerCase()] ?? 0;
        return category.copyWith(productCount: count);
      }).toList();

      categories.assignAll(updatedList);

    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<Category> _parseCategories(Map<String, List<dynamic>> data) {
    final List<Category> parsed = [];
    if (data.isEmpty) return parsed;

    final ids = data['id'] ?? [];
    final names = data['name'] ?? [];
    final descriptions = data['description'] ?? [];
    final icons = data['icon'] ?? [];
    final colors = data['color'] ?? [];
    final productCounts = data['productCount'] ?? [];
    final dates = data['createdAt'] ?? [];

    for (int i = 0; i < names.length; i++) {
      final name = names[i]?.toString().trim() ?? '';
      if (name.isEmpty) continue; // Skip blank rows

      parsed.add(Category(
        id: i < ids.length ? ids[i]?.toString() ?? Helpers.generateId() : Helpers.generateId(),
        name: name,
        description: i < descriptions.length ? descriptions[i]?.toString() ?? '' : '',
        icon: i < icons.length && (icons[i]?.toString().isNotEmpty ?? false)
            ? icons[i].toString()
            : '📦',
        color: i < colors.length && (colors[i]?.toString().isNotEmpty ?? false)
            ? colors[i].toString()
            : '#2196F3',
        productCount: i < productCounts.length
            ? int.tryParse(productCounts[i]?.toString() ?? '0') ?? 0
            : 0,
        createdAt: i < dates.length ? dates[i]?.toString() ?? '' : DateTime.now().toIso8601String(),
      ));
    }

    return parsed;
  }

  Future<void> _saveCategoriesToSheet() async {
    final headers = ['id', 'name', 'description', 'icon', 'color', 'productCount', 'createdAt'];
    final values = <List<dynamic>>[headers];

    for (var category in categories) {
      values.add([
        category.id,
        category.name,
        category.description ?? '',
        category.icon ?? '📦',
        category.color ?? '#2196F3',
        category.productCount,
        category.createdAt,
      ]);
    }

    await _sheets.writeToSheet(
      sheetName: 'Categories',
      values: values,
    );
  }

  Future<void> addCategory() async {
    // Read directly from text controller to prevent empty values
    final inputName = nameController.text.trim();
    final inputDesc = descriptionController.text.trim();

    if (inputName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a category name',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check for duplicate
    if (categories.any((c) => c.name.toLowerCase() == inputName.toLowerCase())) {
      Get.snackbar(
        'Error',
        'Category already exists',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _sheets.init();
      await _sheets.createSheetIfNotExists('Categories');

      final newCategory = Category(
        id: Helpers.generateId(),
        name: inputName,
        description: inputDesc,
        icon: categoryIcon.value,
        color: categoryColor.value,
        createdAt: DateTime.now().toIso8601String(),
      );

      final isFirstCategory = categories.isEmpty;
      categories.add(newCategory);

      if (isFirstCategory) {
        // Safe guard: If this is the first category in an empty sheet, write header + row cleanly
        await _saveCategoriesToSheet();
      } else {
        // Otherwise append to existing structure
        await _sheets.appendToSheet(
          sheetName: 'Categories',
          rowData: [
            newCategory.id,
            newCategory.name,
            newCategory.description ?? '',
            newCategory.icon ?? '📦',
            newCategory.color ?? '#2196F3',
            0,
            newCategory.createdAt,
          ],
        );
      }

      clearForm();
      Get.back();

      Get.snackbar(
        'Success',
        'Category added successfully',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      print('Error adding category: $e');
      Get.snackbar(
        'Error',
        'Failed to add category: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCategory() async {
    final inputName = nameController.text.trim();
    final inputDesc = descriptionController.text.trim();

    if (inputName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a category name',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedCategory.value == null) return;

    try {
      isLoading.value = true;

      final index = categories.indexWhere((c) => c.id == selectedCategory.value!.id);
      if (index != -1) {
        final updatedCategory = selectedCategory.value!.copyWith(
          name: inputName,
          description: inputDesc,
          icon: categoryIcon.value,
          color: categoryColor.value,
        );

        categories[index] = updatedCategory;
        await _saveCategoriesToSheet();

        clearForm();
        Get.back();

        Get.snackbar(
          'Success',
          'Category updated successfully',
          colorText: Colors.green,
          snackPosition: SnackPosition.BOTTOM,
        );
      }

    } catch (e) {
      print('Error updating category: $e');
      Get.snackbar(
        'Error',
        'Failed to update category: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCategory(Category category) async {
    // Check if category has products
    if (category.productCount > 0) {
      Get.snackbar(
        'Cannot Delete',
        'Category has ${category.productCount} products. Reassign them first.',
        colorText: Colors.orange,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      isLoading.value = true;

      categories.removeWhere((c) => c.id == category.id);
      await _saveCategoriesToSheet();

      Get.back();

      Get.snackbar(
        'Success',
        'Category deleted successfully',
        colorText: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      print('Error deleting category: $e');
      Get.snackbar(
        'Error',
        'Failed to delete category: $e',
        colorText: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void editCategory(Category category) {
    isEditing.value = true;
    selectedCategory.value = category;

    nameController.text = category.name;
    descriptionController.text = category.description ?? '';

    categoryName.value = category.name;
    categoryDescription.value = category.description ?? '';
    categoryIcon.value = category.icon ?? '📦';
    categoryColor.value = category.color ?? '#2196F3';
  }

  void clearForm() {
    nameController.clear();
    descriptionController.clear();

    categoryName.value = '';
    categoryDescription.value = '';
    categoryIcon.value = '📦';
    categoryColor.value = '#2196F3';
    isEditing.value = false;
    selectedCategory.value = null;
  }

  void setIcon(String icon) {
    categoryIcon.value = icon;
  }

  void setColor(String color) {
    categoryColor.value = color;
  }

  List<String> getCategoryNames() {
    return categories.map((c) => c.name).toList();
  }

  Category? getCategoryByName(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }
}