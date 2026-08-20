import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/sale_model.dart';
import '../controllers/dashboard_controller.dart';

class RecentSaleCard extends StatelessWidget {
  final Sale sale;

  const RecentSaleCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'unitsAmountFormat'.trParams({
                    'count': sale.quantity.toString(),
                    'amount': dashboardController.formatCurrency(sale.total),
                  }),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sale.date,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}