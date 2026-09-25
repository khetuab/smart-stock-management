import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/order_model.dart';

class OrderHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;

  const OrderHeroStat({
    super.key,
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final String Function(double) formatCurrency;
  final bool showCustomer;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.formatCurrency,
    required this.showCustomer,
    required this.onTap,
  });

  static String statusLabel(String status) =>
      status == 'all' ? 'All' : (status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1));

  static Color statusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = statusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: scheme.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(statusLabel(order.status.tr), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (showCustomer)
                Text(order.customerName, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.quantity.toStringAsFixed(order.quantity % 1 == 0 ? 0 : 2)}x  •  ${formatCurrency(order.offeredPrice)} ea',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  Row(
                    children: [
                      if (order.messages.isNotEmpty) ...[
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('${order.messages.length}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 10),
                      ],
                      Text(formatCurrency(order.total), style: TextStyle(fontWeight: FontWeight.bold, color: scheme.primary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same glass-mesh visual language as Dashboard/Purchase/Debts headers.
class OrdersHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  OrdersHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});

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
      canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }
    glassOrb(Offset(width * 0.88, height * 0.10), 130, Colors.white, 0.14, 70);
    glassOrb(Offset(width * 0.15, height * 0.85), 100, secondaryColor, 0.30, 60);
    glassOrb(Offset(width * 0.55, height * 0.05), 70, Colors.white, 0.10, 40);

    final ringPaint = Paint()..color = Colors.white.withOpacity(0.18)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 34, ringPaint);
    canvas.drawCircle(Offset(width * 0.90, height * 0.28), 51, ringPaint..color = Colors.white.withOpacity(0.08));

    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withOpacity(0.40)],
        stops: const [0.5, 1.0],
      ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant OrdersHeaderPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
}