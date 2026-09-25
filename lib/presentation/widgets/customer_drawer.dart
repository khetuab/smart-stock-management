// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:get/get.dart';
// import '../../app/routes/app_routes.dart';
// import '../controllers/auth_controller.dart';
// import '../controllers/dashboard_controller.dart';
//
// /// Drawer for the customer-facing shell. Deliberately does NOT reuse
// /// AppDrawer — that one links to Sales/Purchases/Debts/Reports/Settings
// /// (admin-only screens with no permission guard), which a browsing
// /// customer must never see or reach.
// class CustomerDrawer extends StatelessWidget {
//   const CustomerDrawer({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final auth = Get.find<AuthController>();
//     final dashboard = Get.find<DashboardController>();
//     final scheme = Theme.of(context).colorScheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final currentRoute = Get.currentRoute;
//
//     return Drawer(
//       width: 288,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
//       ),
//       backgroundColor: Theme.of(context).cardColor,
//       child: Obx(
//             () => Column(
//           children: [
//             SizedBox(
//               height: 200,
//               width: double.infinity,
//               child: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
//                     child: CustomPaint(
//                       painter: _CustomerDrawerHeaderPainter(
//                         primaryColor: scheme.primary,
//                         secondaryColor: scheme.tertiary,
//                         isDark: isDark,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     left: 20,
//                     right: 20,
//                     bottom: 20,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(3),
//                           decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
//                           child: CircleAvatar(
//                             radius: 26,
//                             backgroundColor: Colors.white24,
//                             backgroundImage: dashboard.storeLogo.value.isNotEmpty
//                                 ? NetworkImage(dashboard.storeLogo.value)
//                                 : null,
//                             child: dashboard.storeLogo.value.isEmpty
//                                 ? const Icon(Icons.storefront_rounded, size: 24, color: Colors.white)
//                                 : null,
//                           ),
//                         ).animate().scale(delay: 80.ms, duration: 350.ms, curve: Curves.easeOutBack),
//                         const SizedBox(height: 10),
//                         Text(
//                           dashboard.storeName.value.isEmpty ? 'Smart Stock' : dashboard.storeName.value,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             shadows: [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
//                           ),
//                         ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
//                         const SizedBox(height: 2),
//                         Text(
//                           auth.username.value,
//                           style: const TextStyle(color: Colors.white70, fontSize: 12),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
//                 children: [
//                   _CustomerDrawerItem(
//                     icon: Icons.storefront_rounded,
//                     title: 'browseShop'.tr,
//                     isActive: currentRoute == AppRoutes.customerHome,
//                     onTap: () {
//                       Get.back();
//                       Get.offAllNamed(AppRoutes.customerHome);
//                     },
//                     index: 0,
//                   ),
//                   _CustomerDrawerItem(
//                     icon: Icons.receipt_long_rounded,
//                     title: 'myOrders'.tr,
//                     isActive: currentRoute == AppRoutes.orders,
//                     onTap: () {
//                       Get.back();
//                       Get.toNamed(AppRoutes.orders);
//                     },
//                     index: 1,
//                   ),
//                   _CustomerDrawerItem(
//                     icon: Icons.mosque_rounded,
//                     title: 'islamicTools'.tr,
//                     isActive: currentRoute == AppRoutes.islamicHubc,
//                     onTap: () {
//                       Get.back();
//                       Get.toNamed(AppRoutes.islamicHubc);
//                     },
//                     index: 2,
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     child: Divider(height: 1),
//                   ),
//                   _CustomerDrawerItem(
//                     icon: Icons.settings_rounded,
//                     title: 'settings'.tr,
//                     isActive: currentRoute == AppRoutes.customerSettings,
//                     onTap: () {
//                       Get.back();
//                       Get.toNamed(AppRoutes.customerSettings);
//                     },
//                     index: 3,
//                   ),
//                   // _CustomerDrawerItem(
//                   //   icon: Icons.logout_rounded,
//                   //   title: 'endSession'.tr,
//                   //   isActive: false,
//                   //   color: scheme.error,
//                   //   onTap: () => _confirmEndSession(context, auth),
//                   //   index: 5,
//                   // ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _confirmEndSession(BuildContext context, AuthController auth) {
//     Get.back(); // close drawer
//     Get.dialog(
//       AlertDialog(
//         title: Text('endSessionTitle'.tr),
//         content: Text('endSessionMessage'.tr),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
//           FilledButton(
//             onPressed: () {
//               Get.back();
//               auth.logoutGuest();
//             },
//             child: Text('endSession'.tr),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _CustomerDrawerItem extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback onTap;
//   final bool isActive;
//   final Color? color;
//   final int index;
//
//   const _CustomerDrawerItem({
//     required this.icon,
//     required this.title,
//     required this.onTap,
//     required this.index,
//     this.isActive = false,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final tint = color ?? (isActive ? scheme.primary : scheme.onSurfaceVariant);
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Material(
//         color: isActive ? scheme.primary.withOpacity(0.10) : Colors.transparent,
//         borderRadius: BorderRadius.circular(14),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(14),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             child: Row(
//               children: [
//                 Icon(icon, size: 21, color: tint),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Text(
//                     title,
//                     style: TextStyle(
//                       color: color ?? (isActive ? scheme.primary : scheme.onSurface),
//                       fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//                       fontSize: 14.5,
//                     ),
//                   ),
//                 ),
//                 if (isActive)
//                   Container(width: 6, height: 6, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ).animate().fadeIn(delay: (60 * index).ms, duration: 260.ms).slideX(begin: -0.12, end: 0, curve: Curves.easeOut);
//   }
// }
//
// class _CustomerDrawerHeaderPainter extends CustomPainter {
//   final Color primaryColor;
//   final Color secondaryColor;
//   final bool isDark;
//
//   _CustomerDrawerHeaderPainter({required this.primaryColor, required this.secondaryColor, required this.isDark});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final width = size.width;
//     final height = size.height;
//     final rect = Offset.zero & size;
//
//     final gradient = LinearGradient(
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//       colors: [
//         HSLColor.fromColor(primaryColor).withLightness(isDark ? 0.16 : 0.38).toColor(),
//         primaryColor,
//         HSLColor.fromColor(secondaryColor).withSaturation(0.7).toColor(),
//       ],
//       stops: const [0.0, 0.55, 1.0],
//     );
//     canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
//
//     void glassOrb(Offset center, double radius, Color color, double opacity, double blur) {
//       canvas.drawCircle(center, radius, Paint()..color = color.withOpacity(opacity)..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
//     }
//
//     glassOrb(Offset(width * 0.85, height * 0.15), 80, Colors.white, 0.16, 45);
//     glassOrb(Offset(width * 0.1, height * 0.75), 60, secondaryColor, 0.30, 40);
//
//     canvas.drawRect(
//       rect,
//       Paint()
//         ..shader = LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Colors.transparent, Colors.black.withOpacity(0.30)],
//           stops: const [0.4, 1.0],
//         ).createShader(rect),
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant _CustomerDrawerHeaderPainter oldDelegate) =>
//       oldDelegate.primaryColor != primaryColor || oldDelegate.secondaryColor != secondaryColor || oldDelegate.isDark != isDark;
// }