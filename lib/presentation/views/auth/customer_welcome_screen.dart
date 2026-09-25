// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:get/get.dart';
// import '../../../app/routes/app_routes.dart';
// import '../../controllers/auth_controller.dart';
// import '../../widgets/secret_owner_access.dart';
//
// /// Shown once per customer device, right after they pick "I'm a Customer"
// /// on the RoleSelectionScreen. No password — just a name and phone number
// /// so orders can be tied back to them ("My Orders").
// ///
// /// Calls AuthController.loginAsGuestCustomer(), which is a NEW method —
// /// see PATCH_NOTES.md for the auth_controller.dart patch that adds it.
// class CustomerWelcomeScreen extends GetView<AuthController> {
//   const CustomerWelcomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final nameCtrl = TextEditingController();
//     final phoneCtrl = TextEditingController();
//     final scheme = Theme.of(context).colorScheme;
//
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(28),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Stack(
//                     children:[
//                       Center(
//                       child: Container(
//                         width: 84,
//                         height: 84,
//                         decoration: BoxDecoration(color: scheme.primary.withOpacity(0.10), shape: BoxShape.circle),
//                         child: Icon(Icons.waving_hand_rounded, size: 40, color: scheme.primary),
//                       ),
//                     ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
//                       Positioned(
//                         top: 0,
//                         left: 0,
//                         right: 0,
//                         height: 80,
//                         child: SecretOwnerAccess(child: Container(color: Colors.transparent )),
//                       ),
//                   ]
//                   ),
//                   const SizedBox(height: 22),
//                   Text(
//                     'Tell us who you are'.tr,
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Just your name and phone — no password needed.'.tr,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: scheme.onSurfaceVariant),
//                   ),
//                   const SizedBox(height: 28),
//                   TextField(
//                     controller: nameCtrl,
//                     textCapitalization: TextCapitalization.words,
//                     decoration: InputDecoration(
//                       labelText: 'Your Name'.tr,
//                       prefixIcon: const Icon(Icons.person_outline_rounded),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                   const SizedBox(height: 14),
//                   TextField(
//                     controller: phoneCtrl,
//                     keyboardType: TextInputType.phone,
//                     decoration: InputDecoration(
//                       labelText: 'Phone Number'.tr,
//                       prefixIcon: const Icon(Icons.phone_outlined),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   Obx(() => controller.errorMessage.value.isEmpty
//                       ? const SizedBox.shrink()
//                       : Padding(
//                     padding: const EdgeInsets.only(bottom: 14),
//                     child: Text(
//                       controller.errorMessage.value,
//                       style: TextStyle(color: scheme.error, fontSize: 13),
//                       textAlign: TextAlign.center,
//                     ),
//                   )),
//                   Obx(() => SizedBox(
//                     height: 52,
//                     child: FilledButton(
//                       onPressed: controller.isLoading.value
//                           ? null
//                           : () => controller.loginAsGuestCustomer(name: nameCtrl.text, phone: phoneCtrl.text),
//                       style: FilledButton.styleFrom(
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                       ),
//                       child: controller.isLoading.value
//                           ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
//                       )
//                           : Text('Continue'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
//                     ),
//                   )),
//                   const SizedBox(height: 14),
//                   TextButton(
//                     onPressed: () => Get.offAllNamed(AppRoutes.roleSelection),
//                     child: Text('Not a customer? Go back'.tr),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/secret_owner_access.dart';
import '../customer/customer_registration_screen.dart';

class CustomerWelcomeScreen extends GetView<AuthController> {
  const CustomerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(color: scheme.primary.withOpacity(0.10), shape: BoxShape.circle),
                        child: Icon(Icons.waving_hand_rounded, size: 40, color: scheme.primary),
                      ),
                    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
                        Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: SecretOwnerAccess(child: Container(color: Colors.transparent )),
                      ),
                    ]
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Welcome'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log in to your account, or create one to start ordering.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('Log In'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Get.to(()=>CustomerRegisterScreen()),
                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('Create an Account'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            // Hidden owner-access gesture lives here now, since this is
            // the actual first screen anyone sees before logging in.
            const Positioned(top: 0, left: 0, right: 0, height: 30,
                child: SecretOwnerAccess(child: SizedBox.expand())),
          ],
        ),
      ),
    );
  }
}