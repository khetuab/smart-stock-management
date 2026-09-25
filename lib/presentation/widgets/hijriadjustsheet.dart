import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/hijri_calender_controller.dart';

class HijriAdjustmentSheet extends GetView<HijriCalendarController> {
  const HijriAdjustmentSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const HijriAdjustmentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'calendarAdjustment'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'calendarAdjustmentDesc'.tr,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            Obx(
                  () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: controller.dayAdjustment.value > -2
                        ? () => controller.setDayAdjustment(controller.dayAdjustment.value - 1)
                        : null,
                  ),
                  Column(
                    children: [
                      Text(
                        controller.dayAdjustment.value > 0
                            ? '+${controller.dayAdjustment.value}'
                            : '${controller.dayAdjustment.value}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: scheme.primary),
                      ),
                      Text('days'.tr, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: controller.dayAdjustment.value < 2
                        ? () => controller.setDayAdjustment(controller.dayAdjustment.value + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}