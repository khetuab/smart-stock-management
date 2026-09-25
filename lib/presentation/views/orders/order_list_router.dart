import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../customer/customer_order_list_screen.dart';
import 'order_list_screen.dart';

class OrderListRouter extends StatelessWidget {
  const OrderListRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return auth.isAdmin ? const AdminOrderListScreen() : const CustomerOrderListScreen();
  }
}