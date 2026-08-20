import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/setup_controller.dart';
import 'setup_step_kit.dart';

class ZakatStep extends GetView<SetupController> {
  const ZakatStep({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amber = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    final amberBg = isDark ? const Color(0xFF2A2110) : const Color(0xFFFFF7E8);
    final amberBorder = amber.withOpacity(isDark ? 0.35 : 0.25);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            icon: Icons.volunteer_activism_rounded,
            title: 'zakatCalculationTitle'.tr,
            subtitle: 'zakatCalculationSubtitle'.tr,
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: amberBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: amberBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.mosque_rounded, size: 52, color: amber),
                const SizedBox(height: 14),
                Text(
                  'oneOfFivePillarsTitle'.tr,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: scheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'zakatPillarDescription'.tr,
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Obx(
                () => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: controller.zakatEnabled.value ? scheme.primary : Theme.of(context).dividerColor,
                  width: controller.zakatEnabled.value ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calculate_rounded, color: scheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'enableZakatLabel'.tr,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.zakatEnabled.value
                              ? 'zakatEnabledHelper'.tr
                              : 'zakatDisabledHelper'.tr,
                          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.zakatEnabled.value,
                    onChanged: controller.updateZakatEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Obx(
                () => ValidationBanner(
              isValid: true,
              validText: controller.zakatEnabled.value
                  ? 'zakatFeatureEnabledText'.tr
                  : 'zakatFeatureDisabledText'.tr,
              invalidText: '',
            ),
          ),
        ],
      ),
    );
  }
}