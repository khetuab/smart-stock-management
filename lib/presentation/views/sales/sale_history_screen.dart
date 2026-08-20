import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/sale_model.dart';
import '../../controllers/sale_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'sale_detail_screen.dart';

class SaleHistoryScreen extends GetView<SaleController> {
  const SaleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('saleHistoryTitle'.tr),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildFilterBar(context),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredSales.isEmpty) {
          return AppEmptyState(
            icon: Icons.history_rounded,
            title: 'noSalesFoundTitle'.tr,
            subtitle: 'noSalesFoundSubtitle'.tr,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.filteredSales.length,
          itemBuilder: (context, index) {
            final sale = controller.filteredSales[index];
            return _SaleCard(sale: sale);
          },
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final filterKeys = [
      'filterToday',
      'filterMonday',
      'filterTuesday',
      'filterWednesday',
      'filterThursday',
      'filterFriday',
      'filterSaturday',
      'filterSunday',
      'filterThisWeek',
      'filterThisMonth',
      'filterCustom',
    ];

    final filterValues = [
      'Today',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
      'This Week',
      'This Month',
      'Custom',
    ];

    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterKeys.length,
        itemBuilder: (context, index) {
          final filterKey = filterKeys[index];
          final filterValue = filterValues[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(() {
              final isSelected = controller.selectedFilter.value == filterValue;
              return FilterChip(
                label: Text(filterKey.tr),
                selected: isSelected,
                onSelected: (_) {
                  controller.setSaleFilter(filterValue);
                  if (filterValue == 'Custom') _showCustomDatePicker(context);
                },
                selectedColor: scheme.primary.withOpacity(0.16),
                labelStyle: TextStyle(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              );
            }),
          );
        },
      ),
    );
  }

  void _showCustomDatePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
        DateTime endDate = DateTime.now();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('selectDateRangeTitle'.tr),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('startDateLabel'.tr),
                    subtitle: Text(startDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => startDate = date);
                    },
                  ),
                  ListTile(
                    title: Text('endDateLabel'.tr),
                    subtitle: Text(endDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => endDate = date);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancelButton'.tr),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.customStartDate.value = startDate;
                    controller.customEndDate.value = endDate;
                    controller.applySaleFilters();
                    Navigator.pop(context);
                  },
                  child: Text('applyButton'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;

  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.to(() => SaleDetailScreen(sale: sale)),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(
                  color: sale.isCredit
                      ? (sale.isFullyPaid ? Colors.teal : Colors.orange)
                      : scheme.primary,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sale.productName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusPill(
                      text: sale.isCredit
                          ? (sale.isFullyPaid ? 'paid'.tr : 'credit'.tr)
                          : sale.status,
                      tone: sale.isCredit && !sale.isFullyPaid
                          ? PillTone.warning
                          : PillTone.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Quantity and Price per Unit Chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${sale.quantity.toInt()}x',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '@ ${dashboardController.formatCurrency(sale.sellingPrice)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // Sale Total and Timestamp
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dashboardController.formatCurrency(sale.total),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sale.date} • ${sale.time}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}