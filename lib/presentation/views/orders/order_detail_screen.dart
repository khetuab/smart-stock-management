// lib/presentation/views/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../widgets/app_kits_collection.dart';
import 'order_chat_screen.dart';

class OrderDetailScreen extends GetView<OrderController> {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Get.find<AuthController>();
    final dashboard = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'.tr),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Chat'.tr,
            onPressed: () => Get.to(() => const OrderChatScreen()),
          ),
        ],
      ),
      body: Obx(() {
        final order = controller.selectedOrder.value;
        if (order == null) {
          return Center(child: Text('Order not found'.tr));
        }

        final statusColor = _statusColor(order.status);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.isNotEmpty
                      ? order.status.tr[0].toUpperCase() + order.status.tr.substring(1)
                      : '',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              if (order.isApproved) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text('Approved by Admin'.tr, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product'.tr, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(order.productName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _kv('Quantity'.tr, order.quantity.toStringAsFixed(order.quantity % 1 == 0 ? 0 : 2), scheme)),
                        Expanded(child: _kv('Unit Price'.tr, dashboard.formatCurrency(order.offeredPrice), scheme)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _kv('Total'.tr, dashboard.formatCurrency(order.total), scheme, big: true),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer'.tr, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(order.customerName, style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
                    if (order.customerPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(order.customerPhone, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                    ],
                    if (order.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Notes'.tr, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(order.notes, style: TextStyle(color: scheme.onSurface)),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              // Admin-only negotiation control
              if (auth.isAdmin && order.isPending) ...[
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Negotiate Price'.tr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        'Propose a new unit price — this updates the order without approving it yet.'.tr,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      _PriceProposalRow(orderId: order.id, currentPrice: order.offeredPrice),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
              ],

              const SizedBox(height: 24),

              if (auth.isAdmin && order.isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmReject(context, order.id),
                        icon: const Icon(Icons.close_rounded),
                        label: Text('Reject'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmApprove(context, order.id),
                        icon: const Icon(Icons.check_rounded),
                        label: Text('Approve'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              if (auth.isAdmin && order.isApproved)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.markCompleted(order.id),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text('Mark Completed'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

              if (!auth.isAdmin && order.isPending)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context, order.id),
                    icon: const Icon(Icons.close_rounded),
                    label: Text('Cancel Order'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// Safely format or slice string timestamps without triggering RangeError
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      final isoStr = parsed.toIso8601String().replaceAll('T', ' ');
      return isoStr.substring(0, isoStr.length < 16 ? isoStr.length : 16);
    }
    return dateStr.substring(0, dateStr.length < 16 ? dateStr.length : 16);
  }

  Widget _buildTimelineItem(String title, String rawTime, IconData icon, Color color, ColorScheme scheme) {
    final formattedTime = _formatDate(rawTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                if (formattedTime.isNotEmpty)
                  Text(formattedTime, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value, ColorScheme scheme, {bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 20 : 15,
            fontWeight: FontWeight.bold,
            color: big ? scheme.primary : scheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return const Color(0xFFD97706);
    }
  }

  void _confirmApprove(BuildContext context, String orderId) {
    Get.dialog(
      AlertDialog(
        title: Text('Approve Order?'.tr),
        content: Text('This will deduct the ordered quantity from stock and notify the customer.'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.approveOrder(orderId);
            },
            child: Text('Approve'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: Text('Reject Order?'.tr),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: 'Reason (optional)'.tr, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.rejectOrder(orderId, reason: reasonController.text.trim());
            },
            child: Text('Reject'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, String orderId) {
    Get.dialog(
      AlertDialog(
        title: Text('Cancel this order?'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('No'.tr)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              controller.cancelOrder(orderId);
            },
            child: Text('Yes, Cancel'.tr),
          ),
        ],
      ),
    );
  }
}

class _PriceProposalRow extends StatefulWidget {
  final String orderId;
  final double currentPrice;
  const _PriceProposalRow({required this.orderId, required this.currentPrice});

  @override
  State<_PriceProposalRow> createState() => _PriceProposalRowState();
}

class _PriceProposalRowState extends State<_PriceProposalRow> {
  late final TextEditingController _controller =
  TextEditingController(text: widget.currentPrice.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final orderController = Get.find<OrderController>();

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'New Unit Price'.tr,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () {
            final newPrice = double.tryParse(_controller.text);
            if (newPrice != null && newPrice > 0) {
              orderController.proposeNewPrice(widget.orderId, newPrice);
            }
          },
          child: Text('Send'.tr),
        ),
      ],
    );
  }
}