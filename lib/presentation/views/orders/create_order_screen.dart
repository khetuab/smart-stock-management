// lib/presentation/views/orders/create_order_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/shared_preferences_service.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_kits_collection.dart';

class CreateOrderScreen extends GetView<OrderController> {
  /// Optional — lets a caller (e.g. tapping a product on the customer
  /// shop-front) land here with the product already chosen instead of
  /// making the customer find it again in the dropdown.
  final Product? initialProduct;

  const CreateOrderScreen({super.key, this.initialProduct});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final dashboardController = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Admins only MANAGE orders customers place — they never create one
    // themselves. The FAB on OrderListScreen already hides this path,
    // but this screen is reachable by route name too, so it needs its
    // own guard rather than relying solely on the caller behaving.
    if (auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Create Order'.tr),
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 48, color: scheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'Orders are placed by customers'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'As the shop owner, you manage orders here — you don\'t need to create them yourself.'.tr,
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => Get.back(), child: Text('Go Back'.tr)),
              ],
            ),
          ),
        ),
      );
    }

    // Guest customer's own identity — captured once on
    // CustomerWelcomeScreen — so they never have to retype it here.
    final prefs = Get.find<SharedPreferencesService>();
    final guestName = prefs.getGuestName() ?? '';
    final guestPhone = prefs.getGuestPhone() ?? '';

    final TextEditingController customerNameController = TextEditingController(text: guestName);
    final TextEditingController customerPhoneController = TextEditingController(text: guestPhone);
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController priceController = TextEditingController(
      text: initialProduct != null ? initialProduct!.sellingPrice.toStringAsFixed(2) : '',
    );
    final TextEditingController notesController = TextEditingController();

    // Rx instead of plain locals — the originals were never wired into
    // any Obx dependency, so the Total Amount summary and the submit
    // button's enabled state never actually updated as you typed.
    final selectedProduct = Rxn<Product>(initialProduct);
    final quantity = 1.0.obs;
    final offeredPrice = (initialProduct?.sellingPrice ?? 0.0).obs;
    final customerName = guestName.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Order'.tr),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Place an Order'.tr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Fill in the details below to place your order'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Product Selection
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Product'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Obx(
                            () => DropdownButtonFormField<Product>(
                          // isExpanded + a plain single-line Text item
                          // (no Row/Expanded inside DropdownMenuItem) is
                          // the fix for the RenderFlex "hasSize" crash —
                          // dropdown menus measure item content with an
                          // unbounded width pass, which Expanded can't
                          // satisfy.
                          isExpanded: true,
                          value: selectedProduct.value,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.inventory_2_rounded, color: scheme.primary),
                          ),
                          hint: Text('Search or select a product'.tr),
                          items: productController.products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(
                                '${product.name}  •  ${dashboardController.formatCurrency(product.sellingPrice)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (product) {
                            if (product == null) return;
                            selectedProduct.value = product;
                            offeredPrice.value = product.sellingPrice;
                            priceController.text = product.sellingPrice.toStringAsFixed(2);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // Customer Info — pre-filled from the guest profile
              // captured at CustomerWelcomeScreen. Still editable, in
              // case they're ordering on behalf of someone else.
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Information'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customerNameController,
                      onChanged: (value) => customerName.value = value,
                      decoration: InputDecoration(
                        labelText: 'Customer Name *'.tr,
                        prefixIcon: Icon(Icons.person_outline_rounded, color: scheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: customerPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (optional)'.tr,
                        prefixIcon: Icon(Icons.phone_outlined, color: scheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // Order Details
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              quantity.value = double.tryParse(value) ?? 1;
                            },
                            decoration: InputDecoration(
                              labelText: 'Quantity *'.tr,
                              prefixIcon: Icon(Icons.pin_rounded, color: scheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? scheme.surfaceContainerHigh
                                  : scheme.surfaceContainerHighest.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              offeredPrice.value = double.tryParse(value) ?? 0;
                            },
                            decoration: InputDecoration(
                              labelText: 'Offered Price *'.tr,
                              prefixIcon: Icon(Icons.attach_money_rounded, color: scheme.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? scheme.surfaceContainerHigh
                                  : scheme.surfaceContainerHighest.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes'.tr,
                        prefixIcon: Icon(Icons.notes_rounded, color: scheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 16),

              // Order Summary
              Obx(() {
                final total = quantity.value * offeredPrice.value;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withOpacity(0.12),
                        scheme.primary.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            dashboardController.formatCurrency(total),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Negotiable'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Obx(() {
                  final isValid = selectedProduct.value != null &&
                      customerName.value.trim().isNotEmpty &&
                      quantity.value > 0 &&
                      offeredPrice.value > 0;

                  return ElevatedButton(
                    onPressed: isValid && !controller.isLoading.value
                        ? () {
                      controller.createOrder(
                        productId: selectedProduct.value!.id,
                        productName: selectedProduct.value!.name,
                        customerName: customerNameController.text.trim(),
                        customerPhone: customerPhoneController.text.trim(),
                        quantity: quantity.value,
                        offeredPrice: offeredPrice.value,
                        notes: notesController.text.trim(),
                      );
                      Get.back();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Place Order'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            ],
          ),
        );
      }),
    );
  }
}