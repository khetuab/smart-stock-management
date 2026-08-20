import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/dashboard_controller.dart';

class ReportDetailScreen extends GetView<ReportController> {
  final String? reportType;

  const ReportDetailScreen({super.key, this.reportType});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    // Set report type if provided
    if (reportType != null && reportType!.isNotEmpty) {
      controller.setReportType(reportType!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.selectedReportType.value.tr} ${'reportTitleSuffix'.tr}'),
        backgroundColor: Color(
          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Get.snackbar(
                'downloadSnackbarTitle'.tr,
                'downloadSnackbarMessage'.tr,
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Period
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'reportPeriod'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${controller.reportStartDate.value?.toString().split(' ')[0] ?? ''} - ${controller.reportEndDate.value?.toString().split(' ')[0] ?? ''}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'sales'.tr,
                      dashboardController.formatCurrency(controller.totalSales.value),
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'purchases'.tr,
                      dashboardController.formatCurrency(controller.totalPurchases.value),
                      Colors.red,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildSummaryCard(
                'profit'.tr,
                dashboardController.formatCurrency(controller.estimatedProfit.value),
                controller.estimatedProfit.value >= 0 ? Colors.blue : Colors.orange,
                Icons.attach_money,
              ),

              const SizedBox(height: 24),

              // Sales Chart
              Text(
                'salesOverview'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: controller.dailySalesData.isEmpty
                    ? Center(child: Text('noDataAvailable'.tr))
                    : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: controller.totalSales.value / 5,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < controller.dailySalesData.length) {
                              return Text(
                                controller.dailySalesData[index].label,
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: controller.dailySalesData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value.value,
                          );
                        }).toList(),
                        isCurved: true,
                        color: Color(
                          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                        ),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color(
                            int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                          ).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category Sales
              Text(
                'salesByCategory'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: controller.categorySalesData.isEmpty
                    ? Center(child: Text('noDataAvailable'.tr))
                    : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.categorySalesData.map((data) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(
                            int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                          ).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${data.label}: ${dashboardController.formatCurrency(data.value)}',
                        style: TextStyle(
                          color: Color(
                            int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Best Selling Products
              Text(
                'topSellingProducts'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (controller.bestSellingProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('noDataAvailable'.tr),
                  ),
                )
              else
                ...controller.bestSellingProducts.map((product) {
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                        ).withOpacity(0.1),
                        child: Text(
                          (controller.bestSellingProducts.indexOf(product) + 1).toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(
                              int.parse(dashboardController.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
                            ),
                          ),
                        ),
                      ),
                      title: Text(product['name'] ?? ''),
                      subtitle: Text('${product['quantity']} ${'unitsSold'.tr}'),
                      trailing: Text(
                        dashboardController.formatCurrency(product['revenue'] ?? 0.0),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}