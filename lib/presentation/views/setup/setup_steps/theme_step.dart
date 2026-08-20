import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/themes/app_theme.dart';
import '../../../controllers/setup_controller.dart';
import 'setup_step_kit.dart';

class ThemeStep extends GetView<SetupController> {
  const ThemeStep({super.key});

  static const List<Color> presetColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFFEA580C), // Orange
    Color(0xFF9333EA), // Purple
    Color(0xFFDB2777), // Pink
    Color(0xFF0891B2), // Cyan
    Color(0xFFCA8A04), // Amber
    Color(0xFF65A30D), // Lime
    Color(0xFFDC2626), // Red
    Color(0xFF0D9488), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            icon: Icons.palette_rounded,
            title: 'makeItYoursTitle'.tr,
            subtitle: 'makeItYoursSubtitle'.tr,
          ),
          const SizedBox(height: 24),

          // --- Brand color -----------------------------------------------
          Text('brandColorHeader'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SetupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final color = AppTheme.colorFromHex(controller.themeColor.value);
                  return Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      controller.themeColor.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Obx(
                      () => Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: presetColors.map((color) {
                      final hex = AppTheme.colorToHex(color);
                      final isSelected = controller.themeColor.value.toUpperCase() == hex;

                      return GestureDetector(
                        onTap: () => controller.updateThemeColor(hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: scheme.onSurface, width: 2.5)
                                : Border.all(color: Colors.transparent, width: 2.5),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => _CustomColorPickerDialog(
                          initial: AppTheme.colorFromHex(controller.themeColor.value),
                        ),
                      );
                      if (color != null) {
                        controller.updateThemeColor(AppTheme.colorToHex(color));
                      }
                    },
                    icon: const Icon(Icons.colorize_rounded, size: 18),
                    label: Text('customColorButton'.tr),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Appearance mode ---------------------------------------------
          Text('appearanceHeader'.tr, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Obx(
                () => Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    label: 'lightModeLabel'.tr,
                    icon: Icons.light_mode_rounded,
                    selected: controller.themeMode.value == ThemeMode.light,
                    onTap: () => controller.updateThemeMode(ThemeMode.light),
                    preview: _MiniPreview(color: AppTheme.colorFromHex(controller.themeColor.value), dark: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    label: 'darkModeLabel'.tr,
                    icon: Icons.dark_mode_rounded,
                    selected: controller.themeMode.value == ThemeMode.dark,
                    onTap: () => controller.updateThemeMode(ThemeMode.dark),
                    preview: _MiniPreview(color: AppTheme.colorFromHex(controller.themeColor.value), dark: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    label: 'autoModeLabel'.tr,
                    icon: Icons.brightness_auto_rounded,
                    selected: controller.themeMode.value == ThemeMode.system,
                    onTap: () => controller.updateThemeMode(ThemeMode.system),
                    preview: _MiniPreview(color: AppTheme.colorFromHex(controller.themeColor.value), dark: null),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ValidationBanner(
            isValid: true,
            validText: 'themeSelectedValidText'.tr,
            invalidText: '',
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  const _ModeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(8), child: preview),
            const SizedBox(height: 10),
            Icon(icon, size: 18, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  final Color color;
  final bool? dark;

  const _MiniPreview({required this.color, required this.dark});

  @override
  Widget build(BuildContext context) {
    Widget buildFace(bool isDark) {
      final bg = isDark ? const Color(0xFF121316) : const Color(0xFFF6F7FB);
      final card = isDark ? const Color(0xFF1C1E22) : Colors.white;
      return Container(
        color: bg,
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 24, height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 6),
            Container(
              height: 24,
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 46,
      width: double.infinity,
      child: dark == null
          ? Row(
        children: [
          Expanded(child: buildFace(false)),
          Expanded(child: buildFace(true)),
        ],
      )
          : buildFace(dark!),
    );
  }
}

class _CustomColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _CustomColorPickerDialog({required this.initial});

  @override
  State<_CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late Color selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('customBrandColorTitle'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(color: selected, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: Colors.primaries
                  .map(
                    (color) => GestureDetector(
                  onTap: () => setState(() => selected = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected.value == color.value
                          ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                          : null,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancelButton'.tr)),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text('useColorButton'.tr),
        ),
      ],
    );
  }
}