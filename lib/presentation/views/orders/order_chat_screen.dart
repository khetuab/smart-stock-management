import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/models/order_model.dart';

class OrderChatScreen extends GetView<OrderController> {
  const OrderChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = Get.find<AuthController>();
    final messageController = TextEditingController();
    final scrollController = ScrollController();

    void jumpToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    }

    void sendCurrentText() {
      final text = messageController.text;
      if (text.trim().isEmpty) return;
      final order = controller.selectedOrder.value;
      if (order == null) return;
      controller.sendMessage(order.id, text);
      messageController.clear();
    }

    return Obx(() {
      final order = controller.selectedOrder.value;
      jumpToBottom();

      if (order != null) {
        // Idempotent — only actually writes once per unseen message,
        // safe to call on every rebuild.
        controller.markMessagesSeen(order.id);
      }

      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order?.productName ?? 'Chat'.tr, style: const TextStyle(fontSize: 16)),
              if (order != null)
                Text(
                  auth.isAdmin ? order.customerName : 'Admin'.tr,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
        ),
        body: order == null
            ? Center(child: Text('Order not found'.tr))
            : Column(
          children: [
            Expanded(
              child: order.messages.isEmpty
                  ? Center(
                child: Text(
                  'No messages yet. Start the negotiation!'.tr,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: order.messages.length,
                itemBuilder: (context, index) {
                  final message = order.messages[index];
                  // "Mine" is relative to who's actually looking at the
                  // screen right now — NOT a fixed "admin = right" rule.
                  // That fixed-role version was the bug: a customer's
                  // own messages were rendering on the left, same as
                  // Telegram would never do for your own messages.
                  final isMe = auth.isAdmin ? message.isAdmin : !message.isAdmin;
                  final seenByOther = message.isAdmin ? message.seenByCustomer : message.seenByAdmin;

                  return _MessageBubble(
                    message: message,
                    isMe: isMe,
                    seenByOther: seenByOther,
                    onEdit: isMe && !message.deleted
                        ? () => _showEditDialog(context, controller, order.id, message)
                        : null,
                    onDelete: isMe && !message.deleted
                        ? () => controller.deleteMessage(order.id, message.id)
                        : null,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type a message...'.tr,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withOpacity(0.4),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => sendCurrentText(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                          () => IconButton.filled(
                        onPressed: controller.isSendingMessage.value ? null : sendCurrentText,
                        style: IconButton.styleFrom(backgroundColor: scheme.primary),
                        icon: controller.isSendingMessage.value
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showEditDialog(BuildContext context, OrderController controller, String orderId, OrderMessage message) {
    final ctrl = TextEditingController(text: message.text);
    Get.dialog(
      AlertDialog(
        title: Text('Edit Message'.tr),
        content: TextField(controller: ctrl, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          FilledButton(
            onPressed: () {
              controller.editMessage(orderId, message.id, ctrl.text);
              Get.back();
            },
            child: Text('Save'.tr),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final OrderMessage message;
  final bool isMe;
  final bool seenByOther;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.seenByOther,
    this.onEdit,
    this.onDelete,
  });

  void _showActionsSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text('Edit'.tr),
                  onTap: () {
                    Get.back();
                    onEdit!();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                  title: Text('Delete'.tr, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () {
                    Get.back();
                    onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canAct = onEdit != null || onDelete != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary.withOpacity(0.15),
              child: Icon(
                message.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                size: 16,
                color: scheme.primary,
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: canAct ? () => _showActionsSheet(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? scheme.primary : scheme.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.deleted ? 'This message was deleted'.tr : message.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : scheme.onSurface,
                        fontSize: 14,
                        fontStyle: message.deleted ? FontStyle.italic : FontStyle.normal,
                        decorationColor: isMe ? Colors.white70 : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.edited && !message.deleted) ...[
                          Text(
                            '${'edited'.tr} · ',
                            style: TextStyle(
                              color: isMe ? Colors.white.withOpacity(0.7) : scheme.onSurfaceVariant,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isMe ? Colors.white.withOpacity(0.7) : scheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            seenByOther ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 13,
                            color: seenByOther ? Colors.lightBlueAccent : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary,
              child: Icon(
                message.isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}