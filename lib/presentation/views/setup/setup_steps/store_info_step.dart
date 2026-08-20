import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/setup_controller.dart';
import 'setup_step_kit.dart';

class StoreInfoStep extends GetView<SetupController> {
  const StoreInfoStep({super.key});

  static const currencies = ['ETB', 'USD', 'EUR', 'GBP', 'SAR', 'AED', 'KES'];
  static const languages = ['English', 'Amharic', 'Arabic'];

  @override
  Widget build(BuildContext context) {
    final languageDisplayMap = {
      'English': 'languageEnglish'.tr,
      'Amharic': 'languageAmharic'.tr,
      'Arabic': 'languageArabic'.tr,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            icon: Icons.storefront_rounded,
            title: 'tellUsAboutStoreTitle'.tr,
            subtitle: 'tellUsAboutStoreSubtitle'.tr,
          ),
          const SizedBox(height: 24),

          SetupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SetupFieldLabel('storeNameLabel'.tr, required: true),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'storeNameHint'.tr,
                    prefixIcon: const Icon(Icons.storefront_outlined),
                  ),
                  onChanged: controller.updateStoreName,
                ),
                const SizedBox(height: 18),
                SetupFieldLabel('ownerNameLabel'.tr),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ownerNameHint'.tr,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  onChanged: controller.updateOwnerName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SetupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SetupFieldLabel('currencyLabel'.tr),
                Obx(
                      () => _PillDropdown(
                    value: controller.currency.value,
                    items: currencies,
                    onChanged: controller.updateCurrency,
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: 18),
                SetupFieldLabel('languageLabel'.tr),
                Obx(
                      () => _PillDropdown(
                    value: controller.language.value,
                    items: languages,
                    displayMap: languageDisplayMap,
                    onChanged: controller.updateLanguage,
                    icon: Icons.translate_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Obx(
                () => ValidationBanner(
              isValid: controller.step1Valid.value,
              validText: 'storeInfoValidText'.tr,
              invalidText: 'enterStoreNameInvalidText'.tr,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PillDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Map<String, String>? displayMap;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const _PillDropdown({
    required this.value,
    required this.items,
    this.displayMap,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurfaceVariant),
          borderRadius: BorderRadius.circular(12),
          items: items
              .map(
                (item) => DropdownMenuItem(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(displayMap?[item] ?? item),
                ],
              ),
            ),
          )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}