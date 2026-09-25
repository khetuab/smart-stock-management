import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/product_model.dart';
import '../../data/services/telegram_services.dart';
import '../controllers/dashboard_controller.dart';

class OrderViaTelegramSheet {
  static Future<void> show(BuildContext context, Product product) async {
    final dashboard = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final qtyCtrl = TextEditingController(text: '1');
    final phoneCtrl = TextEditingController();
    final qty = 1.0.obs;
    final phone = ''.obs;
    final submitting = false.obs;

    await Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Order via Telegram'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill in your details and we\'ll open Telegram with everything ready to send.'
                        .tr,
                    style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Product summary card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.surfaceContainerHigh
                          : scheme.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: product.image.isNotEmpty
                                ? Image.network(product.image, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.inventory_2_outlined,
                                  color: scheme.onSurfaceVariant,
                                ))
                                : Icon(
                              Icons.inventory_2_outlined,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dashboard.formatCurrency(product.sellingPrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quantity
                  Text(
                    'Quantity'.tr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          if (qty.value > 1) {
                            qty.value--;
                            qtyCtrl.text = qty.value.toInt().toString();
                          }
                        },
                        icon: const Icon(Icons.remove_rounded, size: 18),
                      ),
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (v) {
                            final parsed = double.tryParse(v);
                            if (parsed != null && parsed > 0) qty.value = parsed;
                          },
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (qty.value < product.quantity) {
                            qty.value++;
                            qtyCtrl.text = qty.value.toInt().toString();
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'Available'.tr}: ${product.quantity.toInt()}',
                    style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: 16),

                  // Phone
                  Text(
                    'Your Phone Number'.tr,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: '+251 9XX XXX XXX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      filled: true,
                      fillColor: isDark
                          ? scheme.surfaceContainerHigh
                          : scheme.surfaceContainerHighest.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => phone.value = v,
                  ),

                  const SizedBox(height: 20),

                  // Total preview
                  Obx(() {
                    final total = qty.value * product.sellingPrice;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            dashboard.formatCurrency(total),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Submit
                  Obx(() {
                    final valid =
                        qty.value > 0 && phone.value.trim().length >= 7;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: (!valid || submitting.value)
                            ? null
                            : () async {
                          submitting.value = true;
                          final ok = await TelegramService.openOrderChat(
                            productName: product.name,
                            category: product.category,
                            unitPrice: product.sellingPrice,
                            quantity: qty.value,
                            customerPhone: phone.value.trim(),
                            currency: dashboard.currency.value,
                            imageUrl: product.image,
                          );
                          submitting.value = false;
                          if (ok) {
                            Get.back();
                          } else {
                            Get.snackbar(
                              'Telegram not found'.tr,
                              'Please install Telegram to place an order.'.tr,
                              colorText: Colors.white,
                              backgroundColor: Colors.red,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: submitting.value
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          'Send via Telegram'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}