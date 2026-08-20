import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/purchase_controller.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';

class PurchaseScreen extends GetView<PurchaseController> {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardController = Get.find<DashboardController>();

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // --- Purchase SliverAppBar ---
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            scrolledUnderElevation: 4,
            surfaceTintColor: scheme.surface,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                tooltip: 'Add Purchase'.tr,
                onPressed: () => _showAddPurchaseBottomSheet(context),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                'Purchase Management'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _PurchaseHeaderPainter(
                      primaryColor: scheme.primary,
                      secondaryColor: scheme.tertiary,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.transparent,
                          Colors.black.withOpacity(0.35),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // --- Live Purchase Stats in Header ---
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 52,
                    child: Obx(() {
                      final totalCost = controller.getTotalPurchaseCost();
                      final creditOutstanding = controller.totalCreditOutstanding;

                      return Row(
                        children: [
                          Expanded(
                            child: _HeroStat(
                              label: 'Total Spend'.tr,
                              value: dashboardController.formatCurrency(totalCost),
                              icon: Icons.shopping_bag_rounded,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 34,
                            color: Colors.white.withOpacity(0.3),
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          Expanded(
                            child: _HeroStat(
                              label: 'Owed to Suppliers'.tr,
                              value: dashboardController.formatCurrency(creditOutstanding),
                              icon: Icons.credit_card_rounded,
                              valueColor: creditOutstanding > 0
                                  ? const Color(0xFFFFD9B3)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // --- Search & Date Filter Row ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHigh
                            : scheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        style: TextStyle(fontSize: 14, color: scheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search purchases...'.tr,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          isDense: true,
                        ),
                        onChanged: controller.searchPurchases,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(() {
                    final isFiltered = controller.selectedDateFilter.value.isNotEmpty &&
                        controller.selectedDateFilter.value != 'All';

                    return PopupMenuButton<String>(
                      tooltip: 'Filter Date'.tr,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Theme.of(context).cardColor,
                      elevation: 8,
                      onSelected: controller.setDateFilter,
                      itemBuilder: (context) => [
                        _buildMenuItem('All', context),
                        _buildMenuItem('Today', context),
                        _buildMenuItem('This Week', context),
                        _buildMenuItem('This Month', context),
                      ],
                      child: Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: isFiltered
                              ? scheme.primary
                              : (isDark
                              ? scheme.surfaceContainerHigh
                              : scheme.surfaceContainerHighest.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: isFiltered ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // --- Purchase List ---
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator.adaptive()),
              );
            }

            if (controller.filteredPurchases.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
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
                          Icons.shopping_bag_outlined,
                          size: 56,
                          color: scheme.primary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No purchases found'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a purchase to restock and track inventory'.tr,
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

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList.separated(
                itemCount: controller.filteredPurchases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final purchase = controller.filteredPurchases[index];
                  final isUnpaidCredit = purchase.isCredit && purchase.balanceDue > 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isUnpaidCredit
                          ? Border.all(color: const Color(0xFFF97316).withOpacity(0.35))
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.18)
                              : scheme.shadow.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.shopping_bag_rounded,
                                color: scheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          purchase.productName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: scheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isUnpaidCredit) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF97316).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'CREDIT'.tr,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFF97316),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${'Qty'.tr}: ${purchase.quantity}${purchase.supplier.isNotEmpty ? ' • ${purchase.supplier}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  dashboardController.formatCurrency(purchase.total),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  purchase.date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isUnpaidCredit) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance owed to supplier'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  dashboardController.formatCurrency(purchase.balanceDue),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF97316),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = controller.selectedDateFilter.value == value;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 10),
          Text(
            value.tr,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? scheme.primary : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPurchaseBottomSheet(BuildContext context) {
    final productController = Get.find<ProductController>();
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    controller.clearForm();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Purchase'.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Product'.tr,
                  filled: true,
                  fillColor: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.inventory_2_rounded, size: 20),
                ),
                value: controller.selectedProduct.value?.id,
                items: productController.products.map((product) {
                  return DropdownMenuItem(
                    value: product.id,
                    child: Text(product.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final selected = productController.products.firstWhere((p) => p.id == value);
                    controller.selectedProduct.value = selected;
                    controller.purchasePrice.value = selected.purchasePrice;
                  }
                },
              ),

              const SizedBox(height: 14),

              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity'.tr,
                  filled: true,
                  fillColor: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.pin_rounded, size: 20),
                ),
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 1.0;
                  controller.purchaseQuantity.value = qty > 0 ? qty : 1.0;
                },
              ),

              const SizedBox(height: 14),

              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Purchase Price'.tr,
                  filled: true,
                  fillColor: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0.0;
                  controller.purchasePrice.value = price;
                },
              ),

              const SizedBox(height: 14),

              TextField(
                decoration: InputDecoration(
                  labelText: 'Supplier'.tr,
                  filled: true,
                  fillColor: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.business_rounded, size: 20),
                ),
                onChanged: (value) => controller.supplier.value = value,
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? scheme.surfaceContainerHigh
                      : scheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Bought on Credit'.tr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Supplier not paid yet'.tr,
                      style: const TextStyle(fontSize: 12)),
                  value: controller.isCreditPurchase.value,
                  activeColor: const Color(0xFFF97316),
                  onChanged: controller.toggleCreditPurchase,
                )),
              ),

              const SizedBox(height: 14),

              Obx(() {
                final total = controller.purchaseQuantity.value * controller.purchasePrice.value;
                final isCredit = controller.isCreditPurchase.value;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCredit
                        ? const Color(0xFFF97316).withOpacity(0.08)
                        : scheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Cost:'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            dashboardController.formatCurrency(total),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: isCredit ? const Color(0xFFF97316) : scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (isCredit) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 14, color: Color(0xFFF97316)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'This amount will be logged as owed to the supplier'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => FilledButton(
                      onPressed: () {
                        controller.addPurchase();
                        Get.back();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: controller.isCreditPurchase.value
                            ? const Color(0xFFF97316)
                            : null,
                      ),
                      child: Text(controller.isCreditPurchase.value
                          ? 'Save as Credit'.tr
                          : 'Save Purchase'.tr),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// **Purchase Header Painter**
/// Same glass-mesh language as Dashboard/Debts headers, themed for supply/restocking.
class _PurchaseHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _PurchaseHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final rect = Offset.zero & size;

    final meshGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
        primaryColor,
        HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
        HSLColor.fromColor(secondaryColor).withLightness(isDark ? 0.14 : 0.30).toColor(),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = meshGradient.createShader(rect));

    void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.88, height * 0.10), 130, Colors.white, 0.14, 70);
    glassOrb(Offset(width * 0.15, height * 0.85), 100, secondaryColor, 0.30, 60);
    glassOrb(Offset(width * 0.55, height * 0.05), 70, Colors.white, 0.10, 40);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34, ringPaint);
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 51, ringPaint..color = Colors.white.withOpacity(0.08));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _PurchaseHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}