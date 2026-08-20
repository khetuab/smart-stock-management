import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/setup_controller.dart';
import 'setup_step_kit.dart';

class LogoStep extends GetView<SetupController> {
  const LogoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            icon: Icons.image_rounded,
            title: 'addStoreLogoTitle'.tr,
            subtitle: 'addStoreLogoSubtitle'.tr,
          ),
          const SizedBox(height: 28),

          Center(
            child: Obx(
                  () => Stack(
                children: [
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1E22) : const Color(0xFFF1F2F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.storeLogo.value.isNotEmpty
                            ? scheme.primary
                            : Theme.of(context).dividerColor,
                        width: controller.storeLogo.value.isNotEmpty ? 3 : 1.5,
                      ),
                      image: controller.storeLogo.value.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(controller.storeLogo.value),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: controller.storeLogo.value.isEmpty
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_rounded, size: 44, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 6),
                        Text(
                          'noLogoYet'.tr,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    )
                        : null,
                  ),
                  if (controller.storeLogo.value.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => controller.storeLogo.value = '',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Obx(
                () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : controller.uploadLogo,
                icon: controller.isLoading.value
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Icon(controller.storeLogo.value.isEmpty ? Icons.upload_rounded : Icons.refresh_rounded),
                label: Text(
                  controller.isLoading.value
                      ? 'uploadingButton'.tr
                      : controller.storeLogo.value.isEmpty
                      ? 'uploadLogoButton'.tr
                      : 'replaceLogoButton'.tr,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          SetupCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'logoBestResultsTip'.tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Obx(
                () => ValidationBanner(
              isValid: controller.storeLogo.value.isNotEmpty,
              validText: 'logoUploadedSuccessText'.tr,
              invalidText: 'uploadLogoToContinueText'.tr,
            ),
          ),
        ],
      ),
    );
  }
}