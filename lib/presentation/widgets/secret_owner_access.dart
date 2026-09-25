// lib/presentation/widgets/secret_owner_access.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/services/shared_preferences_service.dart';

/// Wrap this around an invisible hit area (we use a transparent strip
/// pinned to the very top of CustomerHomeScreen) so the shop owner has a
/// way back into the admin app without it being advertised anywhere.
/// Hold for 10 seconds -> secret password prompt -> on success, routes
/// exactly like the old public "I'm the Shop Owner" card did.
class SecretOwnerAccess extends StatefulWidget {
  final Widget child;
  const SecretOwnerAccess({super.key, required this.child});

  @override
  State<SecretOwnerAccess> createState() => _SecretOwnerAccessState();
}

class _SecretOwnerAccessState extends State<SecretOwnerAccess> {
  Timer? _holdTimer;
  Timer? _progressTicker;
  double _progress = 0;

  static const _holdDuration = Duration(seconds: 10);

  // Fixed secret password. Intentionally NOT stored in SharedPreferences
  // or Google Sheets so it can't be found by inspecting app data on the
  // device — change this before shipping.
  static const String _secretPassword = 'tixolve@khat@123';

  void _startHold() {
    _progress = 0;
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() => _progress += 100 / _holdDuration.inMilliseconds);
      if (_progress >= 1) timer.cancel();
    });
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdDuration, _onHoldComplete);
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _progressTicker?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  void _onHoldComplete() {
    _progressTicker?.cancel();
    if (mounted) setState(() => _progress = 0);
    _showPasswordDialog();
  }

  void _showPasswordDialog() {
    final controller = TextEditingController();
    bool obscure = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            children: [
              TextButton(onPressed: () => Get.offAllNamed(AppRoutes.login), child: Text('Login'.tr)),
              Text('ownerAccessTitle'.tr),
            ],
          ),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'password'.tr,
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDialogState(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (_) => _attemptUnlock(controller.text),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => _attemptUnlock(controller.text), child: Text('continueButton'.tr)),
          ],
        ),
      ),
    );
  }

  void _attemptUnlock(String entered) {
    if (entered != _secretPassword) {
      Get.back();
      Get.snackbar('incorrect'.tr, 'ownerAccessWrongPassword'.tr,
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    Get.back();
    _routeToOwnerFlow();
  }

  Future<void> _routeToOwnerFlow() async {
    final prefs = Get.find<SharedPreferencesService>();
    await prefs.saveDeviceRole('admin');
    final isSetupCompleted = prefs.isSetupCompleted();
    final isLoggedIn = prefs.isLoggedIn();
    if (!isSetupCompleted) {
      Get.offAllNamed(AppRoutes.setup);
    } else if (!isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _cancelHold(),
      onLongPressCancel: _cancelHold,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_progress > 0)
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 2.5,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
        ],
      ),
    );
  }
}