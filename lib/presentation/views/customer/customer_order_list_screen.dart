import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/customer_drawer.dart';
import '../../widgets/order_list_shared.dart';
import '../../widgets/customer_bottom_nar_bar.dart';
import '../orders/create_order_screen.dart';
import '../orders/order_detail_screen.dart';

class CustomerOrderListScreen extends GetView<OrderController> {
  const CustomerOrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboard = Get.find<DashboardController>();

    void goBack() {
      if (Navigator.of(context).canPop()) {
        Get.back();
      } else {
        Get.offAllNamed('/customer-home');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        goBack();
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const CreateOrderScreen()),
          icon: const Icon(Icons.add_rounded),
          label: Text('New Order'.tr),
        ),
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                expandedHeight: 190,
                floating: false,
                pinned: true,
                snap: false,
                elevation: 0,
                scrolledUnderElevation: 4,
                surfaceTintColor: scheme.surface,
                backgroundColor: scheme.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                //leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Back'.tr, onPressed: goBack),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: controller.refresh),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    'My Orders'.tr,
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
                              Expanded(child: OrderHeroStat(label: 'Placed'.tr, value: '$total', icon: Icons.receipt_long_rounded)),
                              Container(width: 1, height: 34, color: Colors.white.withOpacity(0.3), margin: const EdgeInsets.symmetric(horizontal: 14)),
                              Expanded(
                                child: OrderHeroStat(
                                  label: 'Awaiting Reply'.tr, value: '$pending', icon: Icons.hourglass_top_rounded,
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: controller.search,
                    decoration: InputDecoration(
                      hintText: 'Search your orders'.tr,
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
                      subtitle: 'Orders you place will show up here.'.tr,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverList.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        order: order,
                        formatCurrency: dashboard.formatCurrency,
                        showCustomer: false,
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
        bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 1),
      ),
    );
  }
}