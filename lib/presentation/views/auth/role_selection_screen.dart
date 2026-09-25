// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:get/get.dart';
// import '../../../app/routes/app_routes.dart';
// import '../../../data/services/shared_preferences_service.dart';
//
// /// First screen a brand-new install ever sees. Decides which of the two
// /// completely separate experiences this device gets:
// ///   - Shop Owner  -> the existing password-protected admin app
// ///   - Customer    -> a read-only shop-front, no password, no admin data
// ///
// /// The choice is remembered (SharedPreferencesService.saveDeviceRole), so
// /// this screen is only ever shown once per install — see main.dart.
// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//
//     final scheme = Theme.of(context).colorScheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final prefs = Get.find<SharedPreferencesService>();
//
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(28),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Center(
//                 child: Container(
//                   width: 96,
//                   height: 96,
//                   decoration: BoxDecoration(
//                     color: scheme.primary.withOpacity(0.10),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(Icons.storefront_rounded, size: 46, color: scheme.primary),
//                 ),
//               ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
//               const SizedBox(height: 24),
//               Text(
//                 'Welcome to SmartStock'.tr,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context)
//                     .textTheme
//                     .headlineSmall
//                     ?.copyWith(fontWeight: FontWeight.w800, color: scheme.onSurface),
//               ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
//               const SizedBox(height: 8),
//               Text(
//                 'How would you like to continue on this device?'.tr,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
//               ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
//               const SizedBox(height: 40),
//
//               _RoleCard(
//                 icon: Icons.admin_panel_settings_rounded,
//                 title: "I'm the Shop Owner".tr,
//                 subtitle: 'Manage products, sales, orders & reports'.tr,
//                 color: scheme.primary,
//                 onTap: () async {
//                   await prefs.saveDeviceRole('admin');
//                   final isSetupCompleted = prefs.isSetupCompleted();
//                   final isLoggedIn = prefs.isLoggedIn();
//                   if (!isSetupCompleted) {
//                     Get.offAllNamed(AppRoutes.setup);
//                   } else if (!isLoggedIn) {
//                     Get.offAllNamed(AppRoutes.login);
//                   } else {
//                     Get.offAllNamed(AppRoutes.dashboard);
//                   }
//                 },
//               ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
//
//               const SizedBox(height: 16),
//
//               _RoleCard(
//                 icon: Icons.person_outline_rounded,
//                 title: "I'm a Customer".tr,
//                 subtitle: 'Browse products & place orders — no password needed'.tr,
//                 color: isDark ? scheme.tertiary : const Color(0xFF059669),
//                 onTap: () async {
//                   await prefs.saveDeviceRole('customer');
//                   Get.offAllNamed(AppRoutes.customerWelcome);
//                 },
//               ).animate().fadeIn(delay: 260.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _RoleCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final VoidCallback onTap;
//
//   const _RoleCard({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     return Material(
//       color: Theme.of(context).cardColor,
//       borderRadius: BorderRadius.circular(18),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: color.withOpacity(0.25)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
//                 child: Icon(icon, color: color, size: 26),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title,
//                         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: scheme.onSurface)),
//                     const SizedBox(height: 3),
//                     Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
//                   ],
//                 ),
//               ),
//               Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }