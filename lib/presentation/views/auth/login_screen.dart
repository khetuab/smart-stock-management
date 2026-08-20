import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- Painted Hero Header ---
            SizedBox(
              height: 240,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _LoginHeaderPainter(
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
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final logo = dashboardController.storeLogo.value;
                          return Container(
                            width: 84,
                            height: 84,
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null,
                              child: logo.isEmpty
                                  ? Icon(Icons.storefront_rounded, size: 36, color: scheme.primary)
                                  : null,
                            ),
                          );
                        }).animate().scale(delay: 80.ms, duration: 350.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 14),
                        Obx(() => Text(
                          dashboardController.storeName.value.isNotEmpty
                              ? dashboardController.storeName.value
                              : 'appName'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))],
                          ),
                        )).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                        const SizedBox(height: 4),
                        Text(
                          'loginSubtitle'.tr,
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
                        // Username field
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'username'.tr,
                              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: scheme.onSurfaceVariant),
                            ),
                            onChanged: (value) => controller.username.value = value,
                          ),
                        ).animate().fadeIn(delay: 250.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 14),

                        // Password field
                        Obx(() => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            obscureText: controller.obscurePassword.value,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'password'.tr,
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
                            onChanged: (value) => controller.password.value = value,
                          ),
                        )).animate().fadeIn(delay: 300.ms, duration: 300.ms).slideY(begin: 0.1, end: 0),

                        // Error message
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

                        // Login button
                        Obx(() => SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : controller.login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                              'login'.tr,
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )).animate().fadeIn(delay: 350.ms, duration: 300.ms),

                        const SizedBox(height: 12),

                        // Reset password hint
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Get.snackbar(
                                'contactSupportTitle'.tr,
                                'contactSupportMessage'.tr,
                                colorText: scheme.primary,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                            child: Text(
                              'forgotPassword'.tr,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
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

/// Same glass-mesh visual language as Dashboard/Purchase/Debts headers —
/// keeps the login screen visually consistent with the rest of the app
/// instead of looking like a bolted-on separate design.
class _LoginHeaderPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _LoginHeaderPainter({
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

    glassOrb(Offset(width * 0.85, height * 0.12), 110, Colors.white, 0.14, 60);
    glassOrb(Offset(width * 0.12, height * 0.85), 90, secondaryColor, 0.28, 55);
    glassOrb(Offset(width * 0.5, height * 0.02), 60, Colors.white, 0.10, 35);

    final sheenPath = Path()
      ..moveTo(width * 0.30, -20)
      ..lineTo(width * 0.48, -20)
      ..lineTo(width * 0.02, height + 20)
      ..lineTo(width * -0.16, height + 20)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(rect),
    );

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(width * 0.85, height * 0.30), 24, ringPaint);
    canvas.drawCircle(Offset(width * 0.85, height * 0.30), 36, ringPaint..color = Colors.white.withOpacity(0.08));
  }

  @override
  bool shouldRepaint(covariant _LoginHeaderPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}