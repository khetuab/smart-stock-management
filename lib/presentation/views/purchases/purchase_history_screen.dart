import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/purchase_model.dart';
import '../../controllers/purchase_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class PurchaseHistoryScreen extends GetView<PurchaseController> {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'purchaseHistory'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 42,
            child: _buildFilterBar(context),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (controller.filteredPurchases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      size: 56,
                      color: scheme.primary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'noPurchasesRecorded'.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'noPurchasesSubtitle'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: controller.filteredPurchases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final purchase = controller.filteredPurchases[index];
            return _buildPurchaseCard(context, purchase, dashboardController, isDark, scheme);
          },
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final filterKeys = ['filterAll', 'filterToday', 'filterThisWeek', 'filterThisMonth'];
    final filterValues = ['All', 'Today', 'This Week', 'This Month'];
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filterKeys.length,
      itemBuilder: (context, index) {
        final filterKey = filterKeys[index];
        final filterValue = filterValues[index];

        return Obx(() {
          final isSelected = controller.selectedDateFilter.value == filterValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filterKey.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => controller.setDateFilter(filterValue),
              selectedColor: scheme.primary,
              backgroundColor: isDark
                  ? scheme.surfaceContainerHigh
                  : scheme.surfaceContainerHighest.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: false,
            ),
          );
        });
      },
    );
  }

  Widget _buildPurchaseCard(
      BuildContext context,
      Purchase purchase,
      DashboardController dashboardController,
      bool isDark,
      ColorScheme scheme,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.18) : scheme.shadow.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  purchase.productName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'restockedStatus'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'quantityLabel'.tr}: ${purchase.quantity}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (purchase.supplier.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${'supplierLabel'.tr}: ${purchase.supplier}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dashboardController.formatCurrency(purchase.total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${purchase.date} ${purchase.time}',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}