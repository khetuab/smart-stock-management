// pubspec.yaml addition needed:
//   shimmer: ^3.0.0
// (fl_chart, flutter_animate, and get are already in your project)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class ReportsScreen extends GetView<ReportController> {
  const ReportsScreen({super.key});

  Color _themeColor(DashboardController d) {
    return Color(
      int.parse(d.themeColor.value.substring(1, 7), radix: 16) + 0xFF000000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF6F7FB),
      body: Obx(() {
        final color = _themeColor(dashboardController);

        return RefreshIndicator(
          onRefresh: () async => controller.generateReport(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              _ReportsHeader(
                color: color,
                isDark: isDark,
                totalSales: dashboardController.formatCurrency(controller.totalSales.value),
                profit: dashboardController.formatCurrency(controller.estimatedProfit.value),
                onRefresh: controller.generateReport,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: controller.isLoading.value
                      ? const _ReportsSkeleton()
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReportTypeSelector(
                        color: color,
                        selected: controller.selectedReportType.value,
                        onChanged: controller.setReportType,
                      ).animate().fadeIn(duration: 300.ms).slideY(
                          begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),

                      if (controller.selectedReportType.value == 'Custom')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _CustomDateRangeRow(
                            color: color,
                            startDate: controller.reportStartDate.value,
                            endDate: controller.reportEndDate.value,
                            onPickStart: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: controller.reportStartDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) controller.reportStartDate.value = date;
                            },
                            onPickEnd: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: controller.reportEndDate.value ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                controller.reportEndDate.value = date;
                                controller.generateReport();
                              }
                            },
                          ),
                        ).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'totalSales'.tr,
                              value: dashboardController.formatCurrency(controller.totalSales.value),
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'totalPurchases'.tr,
                              value: dashboardController.formatCurrency(controller.totalPurchases.value),
                              icon: Icons.trending_down_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 80.ms, duration: 300.ms).slideY(
                          begin: 0.12, end: 0, delay: 80.ms, duration: 300.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 12),

                      _SummaryCard(
                        title: 'estimatedProfit'.tr,
                        value: dashboardController.formatCurrency(controller.estimatedProfit.value),
                        icon: Icons.savings_rounded,
                        color: controller.estimatedProfit.value >= 0
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF97316),
                        wide: true,
                      ).animate().fadeIn(delay: 140.ms, duration: 300.ms).slideY(
                          begin: 0.12, end: 0, delay: 140.ms, duration: 300.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 26),

                      _SectionTitle(title: 'salesOverview'.tr),
                      const SizedBox(height: 12),
                      _SalesChartCard(
                        color: color,
                        isDark: isDark,
                        data: controller.dailySalesData,
                      ).animate().fadeIn(delay: 200.ms, duration: 350.ms).scaleXY(
                          begin: 0.97, end: 1, delay: 200.ms, duration: 350.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 26),

                      _SectionTitle(title: 'bestSellingProducts'.tr),
                      const SizedBox(height: 12),
                      if (controller.bestSellingProducts.isEmpty)
                        _EmptyCard(
                          icon: Icons.bar_chart_rounded,
                          text: 'noSalesDataAvailable'.tr,
                        )
                      else
                        ...List.generate(controller.bestSellingProducts.length, (index) {
                          final product = controller.bestSellingProducts[index];
                          final maxRevenue = (controller.bestSellingProducts.first['revenue'] ?? 1.0) as num;
                          final revenue = (product['revenue'] ?? 0.0) as num;
                          final ratio = maxRevenue == 0 ? 0.0 : (revenue / maxRevenue).clamp(0.0, 1.0).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RankedProductTile(
                              rank: index + 1,
                              name: product['name'] ?? '',
                              subtitle: '${product['quantity']} ${'unitsSold'.tr}',
                              value: dashboardController.formatCurrency(revenue.toDouble()),
                              ratio: ratio,
                              color: color,
                            ),
                          ).animate().fadeIn(
                              delay: (260 + index * 60).ms,
                              duration: 300.ms).slideX(
                              begin: 0.08, end: 0, delay: (260 + index * 60).ms, duration: 300.ms);
                        }),

                      const SizedBox(height: 26),

                      _SectionTitle(title: 'lowStockProducts'.tr),
                      const SizedBox(height: 12),
                      if (controller.lowStockProducts.isEmpty)
                        _AllGoodCard(text: 'allProductsWellStocked'.tr)
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 300.ms)
                      else
                        ...List.generate(controller.lowStockProducts.length, (index) {
                          final p = controller.lowStockProducts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LowStockTile(
                              name: p.name,
                              current: p.quantity,
                              min: p.minQuantity,
                              onRestock: () => Get.toNamed('/purchases'),
                            ),
                          ).animate().fadeIn(
                              delay: (400 + index * 60).ms,
                              duration: 300.ms).slideX(
                              begin: 0.08, end: 0, delay: (400 + index * 60).ms, duration: 300.ms);
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: const BottomNavBar(currentIndex: 5),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ReportsHeader extends StatelessWidget {
  final Color color;
  final bool isDark;
  final String totalSales;
  final String profit;
  final VoidCallback onRefresh;

  const _ReportsHeader({
    required this.color,
    required this.isDark,
    required this.totalSales,
    required this.profit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 168,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 4,
      backgroundColor: color,
      surfaceTintColor: Theme.of(context).colorScheme.surface,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'refresh'.tr,
          onPressed: onRefresh,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _AnalyticsHeaderPainter(baseColor: color, isDark: isDark)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.25), Colors.transparent, Colors.black.withOpacity(0.35)],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'reportsAndAnalytics'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalSales,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderPill(icon: Icons.savings_rounded, label: profit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeaderPainter extends CustomPainter {
  final Color baseColor;
  final bool isDark;
  _AnalyticsHeaderPainter({required this.baseColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(baseColor).withLightness(isDark ? 0.14 : 0.34).toColor(),
        baseColor,
        HSLColor.fromColor(baseColor).withHue((HSLColor.fromColor(baseColor).hue + 28) % 360).toColor(),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    void orb(Offset c, double r, double opacity, double blur) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    orb(Offset(w * 0.85, h * 0.15), 110, 0.14, 60);
    orb(Offset(w * 0.1, h * 0.9), 90, 0.10, 50);

    // faint ascending bar-chart motif
    final barPaint = Paint()..color = Colors.white.withOpacity(0.10);
    final bases = [0.62, 0.5, 0.72, 0.4, 0.58];
    for (int i = 0; i < bases.length; i++) {
      final barW = w * 0.045;
      final left = w * 0.58 + i * (barW + 8);
      final barH = h * (0.55 - bases[i] * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, h - barH - 10, barW, barH),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsHeaderPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.isDark != isDark;
}

// ---------------------------------------------------------------------------
// Report type selector (animated pill segmented control)
// ---------------------------------------------------------------------------

class _ReportTypeSelector extends StatelessWidget {
  final Color color;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ReportTypeSelector({required this.color, required this.selected, required this.onChanged});

  static const _types = ['Daily', 'Weekly', 'Monthly', 'Custom'];
  static const _labels = {
    'Daily': 'reportTypeDaily',
    'Weekly': 'reportTypeWeekly',
    'Monthly': 'reportTypeMonthly',
    'Custom': 'reportTypeCustom',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _types.map((type) {
          final isSelected = selected == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[type]!.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomDateRangeRow extends StatelessWidget {
  final Color color;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _CustomDateRangeRow({
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  String _fmt(DateTime? d) => d == null ? 'selectDate'.tr : d.toLocal().toString().split(' ')[0];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DateChip(icon: Icons.event_rounded, label: 'startDateLabel'.tr, value: _fmt(startDate), color: color, onTap: onPickStart)),
        const SizedBox(width: 10),
        Expanded(child: _DateChip(icon: Icons.event_available_rounded, label: 'endDateLabel'.tr, value: _fmt(endDate), color: color, onTap: onPickEnd)),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _DateChip({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
                    Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary cards
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : color).withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.22), color.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(fontSize: wide ? 19 : 15.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1D24)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1A1D24)),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart card
// ---------------------------------------------------------------------------

class _SalesChartCard extends StatelessWidget {
  final Color color;
  final bool isDark;
  final List<dynamic> data; // expects .label and .value

  const _SalesChartCard({required this.color, required this.isDark, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: data.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_chart_outlined_rounded, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('noDataAvailable'.tr, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      )
          : BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((d) => d.value as double).reduce((a, b) => a > b ? a : b) * 1.25,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => color,
            //  tooltipBorderRadius: BoarderRadius.,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  rod.toY.toStringAsFixed(0),
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              },
            ),
          ),
          barGroups: List.generate(data.length, (i) {
            final d = data[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.value as double,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withOpacity(0.55)],
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data[index].label as String,
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ranked product tile
// ---------------------------------------------------------------------------

class _RankedProductTile extends StatelessWidget {
  final int rank;
  final String name;
  final String subtitle;
  final String value;
  final double ratio;
  final Color color;

  const _RankedProductTile({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.value,
    required this.ratio,
    required this.color,
  });

  Color get _medalColor {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFB45309);
      default:
        return color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.25 : 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _medalColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(fontWeight: FontWeight.bold, color: _medalColor, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(_medalColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1A1D24))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Low stock tile
// ---------------------------------------------------------------------------

class _LowStockTile extends StatelessWidget {
  final String name;
  final num current;
  final num min;
  final VoidCallback onRestock;

  const _LowStockTile({required this.name, required this.current, required this.min, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const danger = Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: danger.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: danger.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: danger, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  '${'currentLabel'.tr}: $current  •  ${'minLabel'.tr}: $min',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRestock,
            style: TextButton.styleFrom(
              backgroundColor: danger.withOpacity(0.12),
              foregroundColor: danger,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('restockAction'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AllGoodCard extends StatelessWidget {
  final String text;
  const _AllGoodCard({required this.text});

  @override
  Widget build(BuildContext context) {
    const good = Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: good.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: good.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: good),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500, color: good))),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget block(double height, {double width = double.infinity, double radius = 16}) => Container(
      height: height,
      width: width,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
    );

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Column(
        children: [
          block(46, radius: 16),
          Row(
            children: [
              Expanded(child: block(72)),
              const SizedBox(width: 12),
              Expanded(child: block(72)),
            ],
          ),
          block(72),
          block(230, radius: 20),
          block(64),
          block(64),
          block(64),
        ],
      ),
    );
  }
}