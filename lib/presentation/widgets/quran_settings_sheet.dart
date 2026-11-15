import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/themes/app_theme.dart';
import '../controllers/quran_page_controller.dart';
import '../../data/models/quran_page_model.dart' show availableTranslations, availableReciters;
import '../widgets/mejlis_kit.dart';
import 'quran_ornaments.dart';

/// Quran reading settings — "see it as you change it".
///
///  ① Live preview card (Bismillah in your chosen size + paper)
///  ② Appearance: A− / slider / A+ and a Standard ⇄ Sepia paper picker
///  ③ Translations: tap-to-toggle tiles with animated check
///  ④ Recitation: reciter chips + auto-play next ayah
class QuranSettingsSheet extends GetView<QuranReaderController> {
  final ScrollController? scrollController;
  const QuranSettingsSheet({super.key, this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, sc) => QuranSettingsSheet(scrollController: sc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = dark ? const Color(0xFF0B1424) : const Color(0xFFF4F7FC);

    return Material(
      color: sheetBg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: MejlisPalette.gold.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        children: [
          // ── fixed header ──
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: MejlisPalette.gold.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
            child: Row(
              children: [
                const StarMedallion(size: 30, active: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'readingSettings'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),

          // ── scrolling body ──
          Expanded(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                6,
                16,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              children: [
                _PreviewCard(controller: controller, dark: dark),
                const SizedBox(height: 14),
                _appearance(context, scheme, dark),
                const SizedBox(height: 14),
                _translations(context, scheme, dark),
                const SizedBox(height: 14),
                _recitation(context, scheme, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── APPEARANCE ─────────────────────────

  Widget _appearance(BuildContext context, ColorScheme scheme, bool dark) {
    return _SectionCard(
      icon: Icons.palette_outlined,
      title: 'appearance'.tr,
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'arabicFontSize'.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Obx(
                    () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: MejlisPalette.gold.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    controller.fontSize.value.toStringAsFixed(0),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: dark ? MejlisPalette.gold : MejlisPalette.goldDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Obx(() {
            final v = controller.fontSize.value;
            void step(double d) {
              HapticFeedback.selectionClick();
              controller.setFontSize((v + d).clamp(18.0, 40.0).toDouble());
            }

            return Row(
              children: [
                _StepButton(label: 'A', small: true, onTap: v > 18 ? () => step(-2) : null),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: MejlisPalette.gold,
                      inactiveTrackColor: MejlisPalette.gold.withOpacity(0.2),
                      thumbColor: MejlisPalette.gold,
                      overlayColor: MejlisPalette.gold.withOpacity(0.15),
                      showValueIndicator: ShowValueIndicator.onDrag,
                    ),
                    child: Slider(
                      value: v,
                      min: 18,
                      max: 40,
                      divisions: 11,
                      label: v.toStringAsFixed(0),
                      onChanged: controller.setFontSize,
                    ),
                  ),
                ),
                _StepButton(label: 'A', small: false, onTap: v < 40 ? () => step(2) : null),
              ],
            );
          }),
          const SizedBox(height: 10),
          Obx(() {
            final sepia = controller.sepiaMode.value;
            return Row(
              children: [
                Expanded(
                  child: _PaperTile(
                    label: 'standardMode'.tr,
                    paper: dark
                        ? const Color(0xFF17243A)
                        : const Color(0xFFFFFFFF),
                    ink: dark
                        ? const Color(0xFFF4F7FC)
                        : const Color(0xFF17243A),
                    selected: !sepia,
                    onTap: () => controller.setSepiaMode(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PaperTile(
                    label: 'sepiaReadingMode'.tr,
                    paper: const Color(0xFFF2E6C8),
                    ink: const Color(0xFF3B2E1E),
                    selected: sepia,
                    onTap: () => controller.setSepiaMode(true),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Text(
            'sepiaReadingModeDesc'.tr,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── TRANSLATIONS ─────────────────────────

  Widget _translations(BuildContext context, ColorScheme scheme, bool dark) {
    return _SectionCard(
      icon: Icons.translate_rounded,
      title: 'translations'.tr,
      dark: dark,
      trailing: Obx(
            () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: MejlisPalette.gold.withOpacity(0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${controller.activeTranslations.length} / ${availableTranslations.length}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: dark ? MejlisPalette.gold : MejlisPalette.goldDark,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'translationsHint'.tr,
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Obx(
                () => Column(
              children: availableTranslations.map((t) {
                final active = controller.activeTranslations.contains(t.identifier);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.toggleTranslation(t.identifier);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? MejlisPalette.gold.withOpacity(0.12)
                            : scheme.surfaceContainerHighest.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? MejlisPalette.gold : Colors.transparent,
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: active ? MejlisPalette.goldGradient : null,
                              color: active ? null : scheme.surfaceContainerHighest,
                            ),
                            child: Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: active ? const Color(0xFF2A2104) : scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nativeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  t.displayName,
                                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          _CheckDot(active: active),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── RECITATION ─────────────────────────

  Widget _recitation(BuildContext context, ColorScheme scheme, bool dark) {
    return _SectionCard(
      icon: Icons.graphic_eq_rounded,
      title: 'recitation'.tr,
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reciter'.tr,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final selected = controller.reciter.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in availableReciters)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setReciter(r.identifier);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected == r.identifier
                            ? MejlisPalette.goldGradient
                            : LinearGradient(colors: [
                          scheme.surfaceContainerHighest.withOpacity(0.28),
                          scheme.surfaceContainerHighest.withOpacity(0.28),
                        ]),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected == r.identifier
                              ? Colors.transparent
                              : MejlisPalette.gold.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected == r.identifier
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            size: 15,
                            color: selected == r.identifier
                                ? const Color(0xFF2A2104)
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            r.displayName,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selected == r.identifier
                                  ? const Color(0xFF2A2104)
                                  : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Divider(color: MejlisPalette.gold.withOpacity(0.2), height: 20),
          Obx(
                () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: MejlisPalette.gold,
              title: Text(
                'autoPlayNextAyah'.tr,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'autoPlayNextAyahHint'.tr,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
              ),
              value: controller.autoPlayNext.value,
              onChanged: controller.setAutoNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ PIECES ═════════════════════════════

/// Live preview — reacts instantly to font size and paper choice.
class _PreviewCard extends StatelessWidget {
  final QuranReaderController controller;
  final bool dark;
  const _PreviewCard({required this.controller, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sepia = controller.sepiaMode.value && !dark;
      final paper = dark
          ? const Color(0xFF17243A)
          : (sepia
          ? const Color(0xFFEAF0F8)
          : const Color(0xFFFFFFFF));

      final ink = dark
          ? const Color(0xFFF4F7FC)
          : (sepia
          ? const Color(0xFF29415F)
          : const Color(0xFF17243A));

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.5), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: MejlisPalette.gold.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const StarMedallion(size: 22, active: true),
                const SizedBox(width: 8),
                Text(
                  'preview'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: ink.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiriQuran(
                  fontSize: controller.fontSize.value,
                  height: 2.0,
                  color: ink,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool dark;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.dark,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF17243A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MejlisPalette.gold.withOpacity(0.16),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: dark ? MejlisPalette.gold : MejlisPalette.goldDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final bool small;
  final VoidCallback? onTap;
  const _StepButton({required this.label, required this.small, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MejlisPalette.gold.withOpacity(0.12),
            border: Border.all(color: MejlisPalette.gold.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 13 : 20,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature "page" you tap to choose the reading paper.
class _PaperTile extends StatelessWidget {
  final String label;
  final Color paper;
  final Color ink;
  final bool selected;
  final VoidCallback onTap;
  const _PaperTile({
    required this.label,
    required this.paper,
    required this.ink,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.28),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? MejlisPalette.gold : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MejlisPalette.gold.withOpacity(0.4)),
                  ),
                  child: Text(
                    'أبجد',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiriQuran(fontSize: 22, color: ink),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: MejlisPalette.goldGradient,
                      ),
                      child: const Icon(Icons.check_rounded, size: 12, color: Color(0xFF2A2104)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  final bool active;
  const _CheckDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? MejlisPalette.goldGradient : null,
        border: Border.all(
          color: active ? Colors.transparent : MejlisPalette.gold.withOpacity(0.5),
          width: 1.4,
        ),
      ),
      child: AnimatedScale(
        scale: active ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF2A2104)),
      ),
    );
  }
}