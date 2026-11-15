import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/quran_page_model.dart';
import '../../controllers/quran_page_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/quran_ornaments.dart' hide OrnamentDivider;
import '../../widgets/quran_settings_sheet.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  QURAN READER — "illuminated mushaf" redesign
///
///   • Header: tappable surah title (opens a searchable surah picker) with a
///     gold reading-progress line that follows your scroll position
///   • Parchment surface with a faint arabesque pattern; sepia mode
///   • Every ayah is an illuminated card: eight-point star medallion,
///     copy + play actions, Amiri Quran text, and language-tagged translations
///   • The ayah being recited glows gold with a live equalizer
///   • Bottom dock: surah ← [ ⏮ ▶ ⏭  reciter · progress  ⏹ ] → surah
///   • Skeleton loading cards instead of a bare spinner
/// ─────────────────────────────────────────────────────────────────────────

// ═════════════════════════════ TONE ═════════════════════════════

class _Tone {
  final bool dark;
  final Color bg, paper, paperActive, ink, inkSoft, ornament, accent;
  const _Tone({
    required this.dark,
    required this.bg,
    required this.paper,
    required this.paperActive,
    required this.ink,
    required this.inkSoft,
    required this.ornament,
    required this.accent,
  });

  static _Tone of(BuildContext context, {required bool sepia}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _Tone(
        dark: true,
        bg: const Color(0xFF0B1424),
        paper: const Color(0xFF17243A),
        paperActive: const Color(0xFF22334D),
        ink: const Color(0xFFF4F7FC),
        inkSoft: const Color(0xFFA9BBD4),
        ornament: MejlisPalette.gold.withOpacity(0.07),
        accent: MejlisPalette.gold,
      );
    }
    if (sepia) {
      return _Tone(
        dark: false,
        bg: const Color(0xFFF2E6C8),
        paper: const Color(0xFFFBF2DE),
        paperActive: const Color(0xFFF8E7B8),
        ink: const Color(0xFF3B2E1E),
        inkSoft: const Color(0xFF7A6850),
        ornament: MejlisPalette.goldDark.withOpacity(0.08),
        accent: MejlisPalette.goldDark,
      );
    }
    return _Tone(
      dark: false,
      bg: const Color(0xFFF4F7FC),
      paper: const Color(0xFFFFFFFF),
      paperActive: const Color(0xFFEAF0F8),
      ink: const Color(0xFF17243A),
      inkSoft: const Color(0xFF566F88),
      ornament: MejlisPalette.goldDark.withOpacity(0.07),
      accent: MejlisPalette.goldDark,
    );
  }
}

QuranSurahMeta? _metaOf(QuranReaderController c) {
  for (final s in c.surahList) {
    if (s.number == c.currentSurah.value) return s;
  }
  return null;
}

// ═════════════════════════════ SCREEN ═════════════════════════════

class QuranReaderScreen extends GetView<QuranReaderController> {
  const QuranReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tone = _Tone.of(context, sepia: controller.sepiaMode.value);
      return Scaffold(
        backgroundColor: tone.bg,
        body: ArabesqueBackground(
          color: tone.ornament,
          child: SafeArea(
            child: Column(
              children: [
                _ReaderHeader(
                  controller: controller,
                  tone: tone,
                  onPickSurah: () => _showSurahPicker(context),
                ),
                _TranslationRail(controller: controller, tone: tone),
                Expanded(child: _body(tone)),
                _Dock(controller: controller, tone: tone),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _body(_Tone tone) {
    return Obx(() {
      final isBootstrapping = controller.isBootstrapping.value;
      final errorMessage = controller.errorMessage.value;
      final isLoading = controller.isLoading.value;
      final ayahCount = controller.ayahs.length;

      if (isBootstrapping || (isLoading && ayahCount == 0)) {
        return _SkeletonList(tone: tone);
      }

      if (errorMessage.isNotEmpty && ayahCount == 0) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmptyState(
                icon: Icons.wifi_off_rounded,
                title: 'somethingWentWrong'.tr,
                subtitle: errorMessage,
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('retry'.tr),
              ),
            ],
          ),
        );
      }

      return _buildQuranList();
    });
  }

  Widget _buildQuranList() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ScrollablePositionedList.builder(
        key: ValueKey(
          'surah_${controller.currentSurah.value}_'
              '${controller.activeTranslations.join()}',
        ),
        itemScrollController: controller.itemScrollController,
        itemPositionsListener: controller.itemPositionsListener,
        initialScrollIndex: controller.initialAyahIndex.value,
        itemCount: controller.ayahs.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        itemBuilder: (context, index) {
          return _AyahBlock(ayah: controller.ayahs[index], index: index);
        },
      ),
    );
  }

  void _showSurahPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => _SurahPickerSheet(
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// ═════════════════════════════ HEADER ═════════════════════════════

class _ReaderHeader extends StatelessWidget {
  final QuranReaderController controller;
  final _Tone tone;
  final VoidCallback onPickSurah;
  const _ReaderHeader({
    required this.controller,
    required this.tone,
    required this.onPickSurah,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tone.paper, tone.bg.withOpacity(0)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
            child: Row(
              children: [
                if (canPop)
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: tone.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onPickSurah,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Obx(() {
                        final meta = _metaOf(controller);
                        final n = controller.currentSurah.value;
                        final sub = meta == null
                            ? '$n / ${QuranReaderController.totalSurahs}'
                            : '$n / ${QuranReaderController.totalSurahs}  ·  '
                            '${meta.englishName}  ·  ${meta.numberOfAyahs} ${'ayahs'.tr}';
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    meta?.name ?? '${'surah'.tr} $n',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                    style: GoogleFonts.amiriQuran(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: tone.accent,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more_rounded, size: 20, color: tone.accent),
                              ],
                            ),
                            SizedBox(height: 10,),
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tone.inkSoft,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'readingSettings'.tr,
                  icon: Icon(Icons.tune_rounded, color: tone.ink),
                  onPressed: () => QuranSettingsSheet.show(context),
                ),
              ],
            ),
          ),
          _ProgressLine(controller: controller, tone: tone),
        ],
      ),
    );
  }
}

/// Gold line under the header that fills as you read through the surah.
class _ProgressLine extends StatelessWidget {
  final QuranReaderController controller;
  final _Tone tone;
  const _ProgressLine({required this.controller, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.ayahs.length;
      return ValueListenableBuilder<Iterable<ItemPosition>>(
        valueListenable: controller.itemPositionsListener.itemPositions,
        builder: (_, positions, __) {
          double p = 0;
          if (total > 0 && positions.isNotEmpty) {
            final last = positions.map((e) => e.index).reduce(math.max);
            p = ((last + 1) / total).clamp(0.0, 1.0);
          }
          return Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: MejlisPalette.gold.withOpacity(0.18),
              borderRadius: BorderRadius.circular(2),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: p),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: MejlisPalette.goldGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// ═════════════════════════════ TRANSLATION RAIL ═════════════════════════════

class _TranslationRail extends StatelessWidget {
  final QuranReaderController controller;
  final _Tone tone;
  const _TranslationRail({required this.controller, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 0, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MejlisPalette.gold.withOpacity(0.14),
            ),
            child: Icon(Icons.translate_rounded, size: 15, color: tone.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Obx(() {
              // Read the observable directly inside the Obx builder so GetX tracks it.
              final selected = controller.activeTranslations.toList();
              return SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 14),
                  itemCount: availableTranslations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = availableTranslations[i];
                    final active = selected.contains(t.identifier);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.toggleTranslation(t.identifier);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: active
                              ? MejlisPalette.goldGradient
                              : LinearGradient(colors: [tone.paper, tone.paper]),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: active
                                ? Colors.transparent
                                : MejlisPalette.gold.withOpacity(0.4),
                          ),
                          boxShadow: active
                              ? [
                            BoxShadow(
                              color: MejlisPalette.gold.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: active
                                  ? const Padding(
                                padding: EdgeInsets.only(right: 5),
                                child: Icon(Icons.check_rounded,
                                    size: 14, color: Color(0xFF2A2104)),
                              )
                                  : const SizedBox.shrink(),
                            ),
                            Text(
                              t.nativeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: active ? const Color(0xFF2A2104) : tone.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ AYAH BLOCK ═════════════════════════════

class _AyahBlock extends GetView<QuranReaderController> {
  final QuranAyah ayah;
  final int index;
  const _AyahBlock({required this.ayah, required this.index});

  void _copy(BuildContext context) {
    final buf = StringBuffer(ayah.text);
    for (final e in controller.activeTranslations) {
      final t = ayah.translations[e];
      if (t != null && t.isNotEmpty) buf.write('\n\n$t');
    }
    buf.write('\n\n— ${ayah.surahName} : ${ayah.numberInSurah}');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('copied'.tr),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tone = _Tone.of(context, sepia: controller.sepiaMode.value);
      final isThis = controller.playingAyahIndex.value == index;
      final audioOn = isThis && controller.isAudioPlaying.value;

      // Translation lines for every enabled language.
      final lines = <Widget>[];
      for (final e in controller.activeTranslations) {
        final text = ayah.translations[e];
        if (text == null || text.isEmpty) continue;
        final label = availableTranslations
            .firstWhere((t) => t.identifier == e, orElse: () => availableTranslations.first)
            .nativeLabel;
        lines.add(_TranslationLine(
          label: label,
          text: text,
          rtl: e == 'ar.muyassar',
          tone: tone,
        ));
      }

      return GestureDetector(
        onTap: () => controller.playAyah(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isThis
                  ? [MejlisPalette.gold.withOpacity(0.20), tone.paperActive]
                  : [tone.paper, tone.paper],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isThis ? MejlisPalette.gold : MejlisPalette.gold.withOpacity(0.22),
              width: isThis ? 1.6 : 1,
            ),
            boxShadow: isThis
                ? [
              BoxShadow(
                color: MejlisPalette.gold.withOpacity(0.32),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(tone.dark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ayah.numberInSurah == 1) ...[
                _SurahBanner(surahName: ayah.surahName, meta: _metaOf(controller)),
                const SizedBox(height: 10),
              ],

              // ── top row: medallion · equalizer · actions ──
              Row(
                children: [
                  StarMedallion(
                    label: '${ayah.numberInSurah}',
                    size: 38,
                    active: isThis,
                    inkColor: tone.accent,
                  ),
                  const SizedBox(width: 10),
                  if (isThis)
                    EqualizerBars(color: tone.accent, animate: audioOn),
                  const Spacer(),
                  _MiniAction(
                    icon: Icons.copy_rounded,
                    color: tone.inkSoft,
                    tooltip: 'copyAyah'.tr,
                    onTap: () => _copy(context),
                  ),
                  const SizedBox(width: 6),
                  _MiniAction(
                    icon: audioOn ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF2A2104),
                    filled: true,
                    onTap: () {
                      if (audioOn) {
                        controller.pauseRecitation();
                      } else {
                        controller.playAyah(index);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Arabic ──
              Text(
                ayah.text,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiriQuran(
                  fontSize: controller.fontSize.value,
                  height: 2.1,
                  color: tone.ink,
                ),
              ),

              // ── translations ──
              if (lines.isNotEmpty) ...[
                const OrnamentDivider(),
                for (int i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  lines[i],
                ],
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  final String? tooltip;
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: filled ? MejlisPalette.goldGradient : null,
          color: filled ? null : MejlisPalette.gold.withOpacity(0.10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class _TranslationLine extends StatelessWidget {
  final String label;
  final String text;
  final bool rtl;
  final _Tone tone;
  const _TranslationLine({
    required this.label,
    required this.text,
    required this.rtl,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    // Own Directionality so the tag and text sit on the correct side for
    // each language, independent of the RTL list wrapper.
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: MejlisPalette.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: tone.accent,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: tone.ink.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════ SURAH BANNER ═════════════════════════════

class _SurahBanner extends StatelessWidget {
  final String surahName;
  final QuranSurahMeta? meta;
  const _SurahBanner({required this.surahName, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: MejlisPalette.emeraldGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.8), width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const StarMedallion(size: 26, active: true),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '﴾ $surahName ﴿',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: MejlisPalette.gold,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16,),
                  if (meta != null)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${meta!.englishName}  ·  ${meta!.numberOfAyahs} ${'ayahs'.tr}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.78),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const StarMedallion(size: 26, active: true),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════ DOCK (surah nav + player) ═════════════════════════════

class _Dock extends StatelessWidget {
  final QuranReaderController controller;
  final _Tone tone;
  const _Dock({required this.controller, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playing = controller.playingAyahIndex.value;
      final hasSel = playing != -1 && playing < controller.ayahs.length;
      final isPlaying = controller.isAudioPlaying.value;
      final isLoadingAudio = controller.isAudioLoading.value;
      final total = controller.ayahs.length;
      final surah = controller.currentSurah.value;

      final reciterName = availableReciters
          .firstWhere((r) => r.identifier == controller.reciter.value,
          orElse: () => availableReciters.first)
          .displayName;

      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: Row(
          children: [
            _RoundNav(
              icon: Icons.chevron_left_rounded,
              tooltip: 'previous'.tr,
              enabled: surah > 1,
              tone: tone,
              onTap: controller.previousSurah,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  gradient: tone.dark
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF1B3760),
                      Color(0xFF102442),
                    ],
                  )
                      : MejlisPalette.emeraldGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: MejlisPalette.emerald.withOpacity(0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: hasSel
                              ? _PlayerIcon(
                            icon: Icons.skip_previous_rounded,
                            enabled: playing > 0,
                            onTap: () => controller.playAyah(playing - 1),
                          )
                              : const SizedBox.shrink(),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            if (isPlaying) {
                              controller.pauseRecitation();
                            } else {
                              controller.playSurah();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MejlisPalette.goldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: MejlisPalette.gold.withOpacity(0.45),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: isLoadingAudio && !isPlaying
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF2A2104),
                              ),
                            )
                                : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                key: ValueKey(isPlaying),
                                color: const Color(0xFF2A2104),
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: hasSel
                              ? _PlayerIcon(
                            icon: Icons.skip_next_rounded,
                            enabled: playing < total - 1,
                            onTap: () => controller.playAyah(playing + 1),
                          )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasSel
                                    ? '${'reciting'.tr} ${'ayah'.tr} ${controller.ayahs[playing].numberInSurah}'
                                    : 'recitation'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                hasSel ? reciterName : 'tapAyahToListen'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasSel)
                          IconButton(
                            onPressed: controller.stopRecitation,
                            tooltip: 'stop'.tr,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.stop_rounded,
                                color: Colors.white.withOpacity(0.9), size: 22),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.touch_app_rounded,
                                size: 18, color: Colors.white.withOpacity(0.6)),
                          ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: hasSel && total > 0
                          ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 8, 6, 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: (playing + 1) / total),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => LinearProgressIndicator(
                              value: v,
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.18),
                              valueColor: const AlwaysStoppedAnimation(MejlisPalette.gold),
                            ),
                          ),
                        ),
                      )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RoundNav(
              icon: Icons.chevron_right_rounded,
              tooltip: 'next'.tr,
              enabled: surah < QuranReaderController.totalSurahs,
              tone: tone,
              onTap: controller.nextSurah,
            ),
          ],
        ),
      );
    });
  }
}

class _PlayerIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PlayerIcon({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 34,
        height: 44,
        child: Icon(
          icon,
          size: 24,
          color: Colors.white.withOpacity(enabled ? 0.95 : 0.3),
        ),
      ),
    );
  }
}

class _RoundNav extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final _Tone tone;
  final VoidCallback onTap;
  const _RoundNav({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled
            ? () {
          HapticFeedback.selectionClick();
          onTap();
        }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tone.paper,
              border: Border.all(color: MejlisPalette.gold.withOpacity(0.5)),
            ),
            child: Icon(icon, size: 24, color: tone.accent),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════ SKELETON ═════════════════════════════

class _SkeletonList extends StatefulWidget {
  final _Tone tone;
  const _SkeletonList({required this.tone});

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bar(double widthFactor, double h, Color c) => FractionallySizedBox(
    alignment: Alignment.centerLeft,
    widthFactor: widthFactor,
    child: Container(
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(h / 2)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = widget.tone;
    final shape = MejlisPalette.gold.withOpacity(0.22);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Opacity(
          opacity: 0.45 + 0.55 * _c.value,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            itemCount: 4,
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: MejlisPalette.gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: shape),
                      ),
                      const Spacer(),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: shape),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bar(1, 14, shape),
                  const SizedBox(height: 12),
                  _bar(0.82, 14, shape),
                  const SizedBox(height: 12),
                  _bar(0.5, 14, shape),
                  const SizedBox(height: 18),
                  _bar(0.9, 9, shape.withOpacity(0.14)),
                  const SizedBox(height: 8),
                  _bar(0.64, 9, shape.withOpacity(0.14)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════ SURAH PICKER ═════════════════════════════

class _SurahPickerSheet extends StatefulWidget {
  final QuranReaderController controller;
  final ScrollController scrollController;
  const _SurahPickerSheet({required this.controller, required this.scrollController});

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  static const double _extent = 70;
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Glide the list so the current surah is near the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = widget.scrollController;
      if (!sc.hasClients) return;
      final want = (widget.controller.currentSurah.value - 3) * _extent;
      sc.jumpTo(math.max(0.0, math.min(want, sc.position.maxScrollExtent)));
    });
  }

  bool _matches(QuranSurahMeta s) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return s.englishName.toLowerCase().contains(q) ||
        s.name.contains(_query.trim()) ||
        '${s.number}' == q ||
        '${s.number}'.startsWith(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tone = _Tone.of(context, sepia: c.sepiaMode.value);

    return Material(
      color: tone.bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: MejlisPalette.gold.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        children: [
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                const StarMedallion(size: 26, active: true),
                const SizedBox(width: 10),
                Text(
                  'jumpTo'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: tone.ink,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: tone.ink),
              decoration: InputDecoration(
                hintText: 'searchSurah'.tr,
                hintStyle: TextStyle(color: tone.inkSoft),
                prefixIcon: Icon(Icons.search_rounded, color: tone.accent),
                filled: true,
                fillColor: tone.paper,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: MejlisPalette.gold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: MejlisPalette.gold, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final all = c.surahList;
              if (all.isEmpty) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
              final current = c.currentSurah.value;
              final list = all.where(_matches).toList();
              if (list.isEmpty) {
                return Center(
                  child: Text('noResults'.tr, style: TextStyle(color: tone.inkSoft)),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemExtent: _extent,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final s = list[i];
                  final selected = s.number == current;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).pop();
                        c.goToSurah(s.number);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: selected ? MejlisPalette.gold.withOpacity(0.14) : tone.paper,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? MejlisPalette.gold
                                : MejlisPalette.gold.withOpacity(0.18),
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            StarMedallion(
                              label: '${s.number}',
                              size: 42,
                              active: selected,
                              inkColor: tone.accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.englishName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: tone.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.numberOfAyahs} ${'ayahs'.tr}',
                                    style: TextStyle(fontSize: 11.5, color: tone.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              s.name,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiriQuran(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: tone.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}