import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/order_list_shared.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'order_detail_screen.dart';

class AdminOrderListScreen extends GetView<OrderController> {
  const AdminOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = Get.find<DashboardController>();

    void goBack() {
      if (Navigator.of(context).canPop()) {
        Get.back();
      } else {
        Get.offAllNamed('/dashboard');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        goBack();
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
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
                leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back'.tr, onPressed: goBack),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.refresh),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    'All Orders'.tr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: OrdersHeaderPainter(primaryColor: scheme.primary, secondaryColor: scheme.tertiary, isDark: isDark)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.15), Colors.transparent, Colors.black.withOpacity(0.35)],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20, right: 20, bottom: 52,
                        child: Obx(() {
                          final total = controller.orders.length;
                          final pending = controller.pendingCount;
                          return Row(
                            children: [
                              Expanded(child: OrderHeroStat(label: 'Total Orders'.tr, value: '$total', icon: Icons.receipt_long_rounded)),
                              Container(width: 1, height: 34, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 14)),
                              Expanded(
                                child: OrderHeroStat(
                                  label: 'Pending'.tr, value: '$pending', icon: Icons.hourglass_top_rounded,
                                  valueColor: pending > 0 ? const Color(0xFFFFD9B3) : Colors.white,
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

              // --- Needs Your Attention: pending orders, quick-approve ---
              Obx(() {
                final pending = controller.orders.where((o) => o.status == 'pending').toList();
                if (pending.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD97706).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${pending.length} ${'order(s) need your attention'.tr}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...pending.take(3).map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${o.customerName} · ${o.productName}',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, color: scheme.onSurface)),
                              ),
                              TextButton(
                                onPressed: () {
                                  controller.selectOrder(o);
                                  Get.to(() => const OrderDetailScreen());
                                },
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                child: Text('Review'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              }),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: controller.search,
                    decoration: InputDecoration(
                      hintText: 'Search orders'.tr,
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: Obx(() => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: controller.statusOptions.map((status) {
                      final selected = controller.statusFilter.value == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(OrderCard.statusLabel(status.tr)),
                          selected: selected,
                          onSelected: (_) => controller.filterByStatus(status),
                          selectedColor: scheme.primary,
                          labelStyle: TextStyle(color: selected ? Colors.white : scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  )),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              Obx(() {
                if (controller.isLoading.value && controller.orders.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive()));
                }
                final orders = controller.filteredOrders;
                if (orders.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No orders yet'.tr,
                      subtitle: 'Orders placed by customers will show up here.'.tr,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  sliver: SliverList.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        formatCurrency: dashboard.formatCurrency,
                        showCustomer: true,
                        onTap: () {
                          controller.selectOrder(order);
                          Get.to(() => const OrderDetailScreen());
                        },
                      ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }
}