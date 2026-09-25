import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/quran_page_model.dart';
import '../controllers/quran_page_controller.dart';

class QuranSettingsSheet extends GetView<QuranReaderController> {
  const QuranSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const QuranSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
              'readingSettings'.tr,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scheme.onSurface),
            ),
            const SizedBox(height: 20),

            Text('arabicFontSize'.tr, style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
            Obx(
                  () => Slider(
                value: controller.fontSize.value,
                min: 18,
                max: 40,
                divisions: 11,
                label: controller.fontSize.value.toStringAsFixed(0),
                onChanged: controller.setFontSize,
              ),
            ),

            const SizedBox(height: 4),
            Obx(
                  () => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('showTranslation'.tr, style: TextStyle(color: scheme.onSurface)),
                value: controller.showTranslation.value,
                onChanged: controller.setShowTranslation,
              ),
            ),

            Obx(
                  () => AnimatedOpacity(
                opacity: controller.showTranslation.value ? 1 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !controller.showTranslation.value,
                  child: DropdownButtonFormField<String>(
                    value: controller.translationEdition.value,
                    decoration: InputDecoration(
                      labelText: 'translation'.tr,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: availableTranslations
                        .map((t) => DropdownMenuItem(value: t.identifier, child: Text(t.displayName)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.setTranslationEdition(value);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),
            Obx(
                  () => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('sepiaReadingMode'.tr, style: TextStyle(color: scheme.onSurface)),
                subtitle: Text(
                  'sepiaReadingModeDesc'.tr,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                value: controller.sepiaMode.value,
                onChanged: controller.setSepiaMode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}