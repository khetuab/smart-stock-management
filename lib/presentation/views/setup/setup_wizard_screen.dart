import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/setup_controller.dart';
import 'setup_steps/store_info_step.dart';
import 'setup_steps/logo_step.dart';
import 'setup_steps/theme_step.dart';
import 'setup_steps/zakat_step.dart';
import 'setup_steps/credentials_step.dart';

class _StepMeta {
  final IconData icon;
  final String labelKey;
  const _StepMeta(this.icon, this.labelKey);
}

class SetupWizardScreen extends GetView<SetupController> {
  const SetupWizardScreen({super.key});

  static const List<_StepMeta> stepMeta = [
    _StepMeta(Icons.storefront_rounded, 'stepStoreLabel'),
    _StepMeta(Icons.image_rounded, 'stepLogoLabel'),
    _StepMeta(Icons.palette_rounded, 'stepThemeLabel'),
    _StepMeta(Icons.volunteer_activism_rounded, 'stepZakatLabel'),
    _StepMeta(Icons.lock_rounded, 'stepLoginLabel'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header + step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'setUpYourStoreTitle'.tr,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Obx(
                            () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${controller.currentStep.value + 1} / ${controller.totalSteps}',
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Obx(() => _StepIndicator(current: controller.currentStep.value)),
                ],
              ),
            ),

            // Step content
            Expanded(
              child: Obx(
                    () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: IndexedStack(
                    key: ValueKey(controller.currentStep.value),
                    index: controller.currentStep.value,
                    children: const [
                      StoreInfoStep(),
                      LogoStep(),
                      ThemeStep(),
                      ZakatStep(),
                      CredentialsStep(),
                    ],
                  ),
                ),
              ),
            ),

            // Footer nav
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Obx(
                    () => Row(
                  children: [
                    if (controller.currentStep.value > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.previousStep,
                          child: Text('backButton'.tr),
                        ),
                      ),
                    if (controller.currentStep.value > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: controller.currentStep.value < controller.totalSteps - 1
                          ? ElevatedButton(
                        onPressed: controller.isStepValid(controller.currentStep.value)
                            ? controller.nextStep
                            : null,
                        child: Text('continueButton'.tr),
                      )
                          : ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.isStepValid(controller.currentStep.value)
                            ? controller.completeSetup
                            : null,
                        child: controller.isLoading.value
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text('finishSetupButton'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered step circles with a connecting progress line — replaces the
/// plain LinearProgressIndicator with something that shows exactly where
/// the merchant is in the flow and which steps are already done.
class _StepIndicator extends StatelessWidget {
  final int current;

  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final steps = SetupWizardScreen.stepMeta;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftDone = (i - 1) ~/ 2 < current;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: leftDone ? scheme.primary : Theme.of(context).dividerColor,
            ),
          );
        }

        final index = i ~/ 2;
        final isDone = index < current;
        final isActive = index == current;
        final meta = steps[index];

        final Color circleColor = isDone || isActive
            ? scheme.primary
            : (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF23262B)
            : const Color(0xFFEDEEF3));
        final Color iconColor = isDone || isActive ? scheme.onPrimary : scheme.onSurfaceVariant;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: isActive ? Border.all(color: scheme.primary.withOpacity(0.3), width: 4) : null,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : meta.icon,
                size: 16,
                color: iconColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}