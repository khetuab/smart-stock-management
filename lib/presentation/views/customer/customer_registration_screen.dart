import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class CustomerRegisterScreen extends GetView<AuthController> {
  const CustomerRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Confirm-password has its own obscure state — the original always
    // hid it with no toggle, which is inconsistent with the password
    // field right above it once we add a visibility icon there too.
    final obscureConfirm = true.obs;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Painted Hero Header (same glass-mesh language as Login) ---
            SizedBox(
              height: 210,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _RegisterHeaderPainter(
                      primaryColor: scheme.primary,
                      secondaryColor: scheme.tertiary,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.transparent,
                          Colors.black.withOpacity(0.30),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Back button — Login is the entry point so it doesn't
                  // need one, but Register is a step away from it.
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, size: 34, color: Colors.white),
                        ).animate().scale(delay: 80.ms, duration: 350.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 14),
                        Text(
                          'Create an Account'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                        ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                        const SizedBox(height: 4),
                        Text(
                          'registerSubtitle'.tr,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Floating Form Card ---
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Username
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: usernameCtrl,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Username'.tr,
                              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 14),

                        // Phone Number
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Phone Number'.tr,
                              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.phone_outlined, color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ).animate().fadeIn(delay: 290.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 14),

                        // Password
                        Obx(() => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: passwordCtrl,
                            obscureText: controller.obscurePassword.value,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Password'.tr,
                              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                          ),
                        )).animate().fadeIn(delay: 330.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 14),

                        // Confirm Password
                        Obx(() => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            controller: confirmCtrl,
                            obscureText: obscureConfirm.value,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password'.tr,
                              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: scheme.onSurfaceVariant),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm.value
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                                onPressed: () => obscureConfirm.value = !obscureConfirm.value,
                              ),
                            ),
                          ),
                        )).animate().fadeIn(delay: 370.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        // Error message — same card style as Login's
                        Obx(() {
                          if (controller.errorMessage.value.isEmpty) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(top: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    controller.errorMessage.value,
                                    style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        // Submit
                        Obx(() => SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                              if (passwordCtrl.text != confirmCtrl.text) {
                                controller.errorMessage.value = 'passwordsDoNotMatch'.tr;
                                return;
                              }
                              controller.registerCustomer(
                                username: usernameCtrl.text,
                                password: passwordCtrl.text,
                                phone: phoneCtrl.text,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: controller.isLoading.value
                                ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                              ),
                            )
                                : Text(
                              'Create Account'.tr,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )).animate().fadeIn(delay: 410.ms, duration: 300.ms),

                        const SizedBox(height: 12),

                        // Back-to-login hint, mirroring Login's "forgot password" link
                        Center(
                          child: TextButton(
                            onPressed: () => Get.back(),
                            child: Text(
                              'alreadyHaveAccount'.tr,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same glass-mesh visual language as Login/Dashboard headers — kept as
/// its own class (rather than reusing Login's private painter) since
/// Dart's library-private types can't cross files.
class _RegisterHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _RegisterHeaderPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

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
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    glassOrb(Offset(width * 0.15, height * 0.15), 100, Colors.white, 0.14, 60);
    glassOrb(Offset(width * 0.88, height * 0.80), 90, secondaryColor, 0.28, 55);
    glassOrb(Offset(width * 0.5, height * 0.02), 60, Colors.white, 0.10, 35);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(width * 0.15, height * 0.65), 24, ringPaint);
    canvas.drawCircle(Offset(width * 0.15, height * 0.65), 36, ringPaint..color = Colors.white.withOpacity(0.08));
  }

  @override
  bool shouldRepaint(covariant _RegisterHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}