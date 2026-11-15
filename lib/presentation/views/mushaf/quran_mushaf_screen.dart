import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/themes/app_theme.dart';
import '../../../data/models/quran_mushaf_models.dart';
import '../../controllers/quran_mushaf_controller.dart';
import '../../widgets/mejlis_kit.dart';
import '../../widgets/quran_ornaments.dart' hide OrnamentDivider;

/// ─────────────────────────────────────────────────────────────────────────
///  QURAN MUSHAF — "printed book" redesign (604 pages · 15 lines)
///
///   • Real book-page feel: double gold frame, corner stars, a soft spine
///     shadow that alternates sides on odd/even pages, juz + surah header,
///     star page-number footer
///   • Every one of the 15 lines is stretched edge to edge (true
///     justification) and always fits the page: no inner scrolling
///   • Surah banners are emerald cartouches; Bismillah is centred
///   • Pages tilt and fade slightly as you swipe
///   • Tap any word → ayah sheet (Arabic + translation + copy)
///   • Bottom dock with a page scrubber you can drag through all 604 pages
///   • Jump sheet: page / searchable surah list / juz grid
///   • Skeleton page while loading, light · sepia · dark aware
/// ─────────────────────────────────────────────────────────────────────────

// ═════════════════════════════ TONE ═════════════════════════════

class _Tone {
  final bool dark;
  final Color bg, paper, ink, inkSoft, ornament, accent;
  const _Tone({
    required this.dark,
    required this.bg,
    required this.paper,
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
        bg: const Color(0xFF0A130F),
        paper: const Color(0xFF101C16),
        ink: const Color(0xFFEDE7D6),
        inkSoft: const Color(0xFFB4AE9D),
        ornament: MejlisPalette.gold.withOpacity(0.07),
        accent: MejlisPalette.gold,
      );
    }
    if (sepia) {
      return _Tone(
        dark: false,
        bg: const Color(0xFFEADCB8),
        paper: const Color(0xFFF3E7CE),
        ink: const Color(0xFF3B2E1E),
        inkSoft: const Color(0xFF7A6850),
        ornament: MejlisPalette.goldDark.withOpacity(0.08),
        accent: MejlisPalette.goldDark,
      );
    }
    return _Tone(
      dark: false,
      bg: const Color(0xFFF7F1E3),
      paper: const Color(0xFFFFFDF8),
      ink: const Color(0xFF1C1C1C),
      inkSoft: const Color(0xFF5E6A62),
      ornament: MejlisPalette.goldDark.withOpacity(0.07),
      accent: MejlisPalette.goldDark,
    );
  }
}

/// Global ayah number currently open in the ayah sheet (tinted on the page).
final ValueNotifier<int?> _highlightedAyah = ValueNotifier<int?>(null);

// ═════════════════════════════ SCREEN ═════════════════════════════

class QuranMushafScreen extends GetView<QuranMushafController> {
  const QuranMushafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tone = _Tone.of(context, sepia: controller.sepiaMode.value);
      final booting = controller.isBootstrapping.value;
      return Scaffold(
        backgroundColor: tone.bg,
        body: ArabesqueBackground(
          color: tone.ornament,
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  controller: controller,
                  tone: tone,
                  onJump: () => _showJumpSheet(context),
                ),
                Expanded(
                  child: booting
                      ? _PageSkeleton(tone: tone)
                  // RTL + reverse: swiping right→left moves forward, like a
                  // physical Arabic book (page 1 → 2 → 3 …).
                      : Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: controller.pageController,
                      reverse: true,
                      physics: const PageScrollPhysics(),
                      itemCount: QuranMushafController.totalPages,
                      onPageChanged: (i) {
                        HapticFeedback.selectionClick();
                        controller.onPageChanged(i);
                      },
                      itemBuilder: (context, index) =>
                          _MushafPageView(pageNumber: index + 1),
                    ),
                  ),
                ),
                if (!booting) _Dock(controller: controller, tone: tone),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showJumpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JumpSheet(controller: controller),
    );
  }
}

// ═════════════════════════════ HEADER ═════════════════════════════

class _Header extends StatelessWidget {
  final QuranMushafController controller;
  final _Tone tone;
  final VoidCallback onJump;
  const _Header({required this.controller, required this.tone, required this.onJump});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Column(
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
                  onTap: onJump,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Obx(() {
                      final page = controller.pages[controller.currentPage.value];
                      final first = (page != null && page.ayahs.isNotEmpty) ? page.ayahs.first : null;
                      final sub = [
                        if (first != null) first.surahNameEnglish,
                        if (page != null) '${'juz'.tr} ${page.juzNumber}',
                        '${'page'.tr} ${controller.currentPage.value}',
                      ].join('  ·  ');
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  first?.surahNameArabic ?? 'quran'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiriQuran(
                                    fontSize: 24,
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
                onPressed: () => _MushafSettingsSheet.show(context),
              ),
            ],
          ),
        ),
        // Whole-Quran progress line
        Obx(() {
          final p = controller.currentPage.value / QuranMushafController.totalPages;
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
                  widthFactor: v.clamp(0.0, 1.0),
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
        }),
      ],
    );
  }
}

// ═════════════════════════════ PAGE ═════════════════════════════

class _MushafPageView extends GetView<QuranMushafController> {
  final int pageNumber;
  const _MushafPageView({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    // The page content is built once (`child`); only the light 3D tilt
    // re-runs while the PageController is animating.
    return AnimatedBuilder(
      animation: controller.pageController,
      child: Obx(() => _content(context)),
      builder: (context, child) {
        final pc = controller.pageController;
        double d = 0;
        if (pc.hasClients && pc.position.hasPixels && pc.position.hasContentDimensions) {
          d = ((pc.page ?? (pageNumber - 1).toDouble()) - (pageNumber - 1)).clamp(-1.0, 1.0);
        }
        if (d == 0) return child!;
        return Opacity(
          opacity: 1 - 0.35 * d.abs(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(d * 0.35)
              ..scale(1 - 0.05 * d.abs()),
            child: child,
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final tone = _Tone.of(context, sepia: controller.sepiaMode.value);
    final page = controller.pages[pageNumber];
    final isLoading = controller.loadingPages.contains(pageNumber);
    final failed = controller.failedPages.contains(pageNumber);

    if (failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MejlisPalette.gold.withOpacity(0.14),
              ),
              child: Icon(Icons.wifi_off_rounded, size: 34, color: tone.accent),
            ),
            const SizedBox(height: 12),
            Text(
              'failedToLoadQuranPage'.tr,
              style: TextStyle(fontWeight: FontWeight.w700, color: tone.ink),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => controller.retryPage(pageNumber),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('retry'.tr),
            ),
          ],
        ),
      );
    }

    if (page == null || isLoading) return _PageSkeleton(tone: tone);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: _BookPage(page: page, tone: tone),
    );
  }
}

class _BookPage extends StatelessWidget {
  final MushafPage page;
  final _Tone tone;
  const _BookPage({required this.page, required this.tone});

  @override
  Widget build(BuildContext context) {
    // In an Arabic book the right-hand page is odd, so its spine is on the left.
    final spineOnLeft = page.pageNumber.isOdd;
    final spineShadow = Colors.brown.withOpacity(tone.dark ? 0.35 : 0.16);
    final first = page.ayahs.isNotEmpty ? page.ayahs.first : null;

    return Container(
      decoration: BoxDecoration(
        color: tone.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MejlisPalette.gold.withOpacity(0.6), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(tone.dark ? 0.4 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // spine shadow
            Positioned(
              top: 0,
              bottom: 0,
              left: spineOnLeft ? 0 : null,
              right: spineOnLeft ? null : 0,
              width: 30,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: spineOnLeft ? Alignment.centerLeft : Alignment.centerRight,
                    end: spineOnLeft ? Alignment.centerRight : Alignment.centerLeft,
                    colors: [spineShadow, spineShadow.withOpacity(0)],
                  ),
                ),
              ),
            ),
            // inner frame + content
            Padding(
              padding: const EdgeInsets.all(7),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MejlisPalette.gold.withOpacity(0.32)),
                ),
                child: Column(
                  children: [
                    // header: juz chip · surah name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: MejlisPalette.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${'juz'.tr} ${page.juzNumber}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: tone.accent,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (first != null)
                          Text(
                            first.surahNameArabic,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiriQuran(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tone.accent,
                            ),
                          ),
                      ],
                    ),
                    const _GoldRule(),
                    // the 15 lines — each gets an equal slice of the page
                    Expanded(
                      child: Column(
                        children: [
                          for (final line in page.lines)
                            Expanded(
                              child: _MushafLineWidget(line: line, page: page, tone: tone),
                            ),
                        ],
                      ),
                    ),
                    const _GoldRule(),
                    StarMedallion(
                      label: '${page.pageNumber}',
                      size: 34,
                      inkColor: tone.accent,
                    ),
                  ],
                ),
              ),
            ),
            // corner stars
            const Positioned(top: 2, left: 2, child: StarMedallion(size: 14, active: true)),
            const Positioned(top: 2, right: 2, child: StarMedallion(size: 14, active: true)),
            const Positioned(bottom: 2, left: 2, child: StarMedallion(size: 14, active: true)),
            const Positioned(bottom: 2, right: 2, child: StarMedallion(size: 14, active: true)),
          ],
        ),
      ),
    );
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          MejlisPalette.gold.withOpacity(0),
          MejlisPalette.gold.withOpacity(0.65),
          MejlisPalette.gold.withOpacity(0),
        ]),
      ),
    );
  }
}

// ═════════════════════════════ LINES ═════════════════════════════

class _MushafLineWidget extends GetView<QuranMushafController> {
  final MushafLine line;
  final MushafPage page;
  final _Tone tone;
  const _MushafLineWidget({required this.line, required this.page, required this.tone});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fontSize = controller.fontSize.value;

      switch (line.kind) {
        case MushafLineKind.blank:
          return const SizedBox.shrink();

        case MushafLineKind.bismillah:
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiriQuran(fontSize: fontSize * 1.05, color: tone.ink),
              ),
            ),
          );

        case MushafLineKind.surahBanner:
          final english = line.bannerText ?? '';
          String arabic = english;
          for (final a in page.ayahs) {
            if (a.surahNameEnglish == english) {
              arabic = a.surahNameArabic;
              break;
            }
          }
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: MejlisPalette.emeraldGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MejlisPalette.gold.withOpacity(0.85), width: 1.1),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StarMedallion(size: 20, active: true),
                    const SizedBox(width: 10),
                    Text(
                      '﴾ $arabic ﴿',
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiriQuran(
                        fontSize: fontSize * 0.95,
                        fontWeight: FontWeight.bold,
                        color: MejlisPalette.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      english,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const StarMedallion(size: 20, active: true),
                  ],
                ),
              ),
            ),
          );

        case MushafLineKind.text:
          return LayoutBuilder(builder: (context, box) {
            final words = _buildWords(context, fontSize);
            // Very short lines (a surah's last line) are centred instead of
            // being stretched, like in print.
            final justify = words.length > 4;
            final row = Row(
              mainAxisSize: justify ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment:
              justify ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: words,
            );
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: justify ? box.maxWidth : 0),
                  child: justify ? IntrinsicWidth(child: row) : row,
                ),
              ),
            );
          });
      }
    });
  }

  List<Widget> _buildWords(BuildContext context, double fontSize) {
    final style = GoogleFonts.amiriQuran(fontSize: fontSize, height: 1.5, color: tone.ink);
    final out = <Widget>[];
    for (final seg in line.segments) {
      final parts = seg.words.split(' ').where((w) => w.isNotEmpty).toList();
      for (int i = 0; i < parts.length; i++) {
        out.add(_Word(
          text: parts[i],
          ayah: seg.ayah,
          style: style,
          tone: tone,
          onTap: () => _AyahSheet.show(context, seg.ayah, tone),
        ));
        if (i == parts.length - 1 && seg.endsAyahHere) {
          out.add(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: StarMedallion(
              label: '${seg.ayah.numberInSurah}',
              size: fontSize * 1.25,
              inkColor: tone.accent,
            ),
          ));
        }
      }
    }
    return out;
  }
}

class _Word extends StatelessWidget {
  final String text;
  final MushafAyah ayah;
  final TextStyle style;
  final _Tone tone;
  final VoidCallback onTap;
  const _Word({
    required this.text,
    required this.ayah,
    required this.style,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ValueListenableBuilder<int?>(
        valueListenable: _highlightedAyah,
        builder: (_, hl, child) {
          final on = hl == ayah.globalAyahNumber;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: on ? MejlisPalette.gold.withOpacity(0.24) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: child,
          );
        },
        child: Text(text, textDirection: TextDirection.rtl, style: style),
      ),
    );
  }
}

// ═════════════════════════════ AYAH SHEET ═════════════════════════════

class _AyahSheet extends GetView<QuranMushafController> {
  final MushafAyah ayah;
  final _Tone tone;
  const _AyahSheet({required this.ayah, required this.tone});

  static void show(BuildContext context, MushafAyah ayah, _Tone tone) {
    HapticFeedback.selectionClick();
    _highlightedAyah.value = ayah.globalAyahNumber;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (_) => _AyahSheet(ayah: ayah, tone: tone),
    ).whenComplete(() => _highlightedAyah.value = null);
  }

  @override
  Widget build(BuildContext context) {
    final translation = ayah.translation;
    final maxH = MediaQuery.of(context).size.height * 0.7;

    return Material(
      color: tone.bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: MejlisPalette.gold.withOpacity(0.45), width: 1.5),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MejlisPalette.gold.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    StarMedallion(
                      label: '${ayah.numberInSurah}',
                      size: 40,
                      active: true,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ayah.surahNameEnglish,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: tone.ink,
                            ),
                          ),
                          Text(
                            '${'ayah'.tr} ${ayah.numberInSurah}  ·  ${'juz'.tr} ${ayah.juz}  ·  ${'page'.tr} ${ayah.page}',
                            style: TextStyle(fontSize: 11.5, color: tone.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ayah.surahNameArabic,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiriQuran(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tone.accent,
                      ),
                    ),
                  ],
                ),
                const OrnamentDivider(),
                Obx(() => Text(
                  ayah.text,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiriQuran(
                    fontSize: controller.fontSize.value + 6,
                    height: 2.0,
                    color: tone.ink,
                  ),
                )),
                const SizedBox(height: 6),
                if (translation != null && translation.isNotEmpty) ...[
                  const OrnamentDivider(),
                  Text(
                    translation,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.65,
                      color: tone.ink.withOpacity(0.88),
                    ),
                  ),
                ] else
                  Obx(() {
                    if (controller.showTranslation.value) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MejlisPalette.gold.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.translate_rounded, color: tone.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'enableTranslationHint'.tr,
                              style: TextStyle(fontSize: 12.5, color: tone.inkSoft),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.setShowTranslation(true);
                              Navigator.of(context).pop();
                            },
                            child: Text('showTranslation'.tr),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final buf = StringBuffer(ayah.text);
                    if (translation != null && translation.isNotEmpty) buf.write('\n\n$translation');
                    buf.write('\n\n— ${ayah.surahNameEnglish} : ${ayah.numberInSurah}');
                    Clipboard.setData(ClipboardData(text: buf.toString()));
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text('copied'.tr),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(milliseconds: 1200),
                      ));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text('copyAyah'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════ DOCK (scrubber) ═════════════════════════════

class _Dock extends StatefulWidget {
  final QuranMushafController controller;
  final _Tone tone;
  const _Dock({required this.controller, required this.tone});

  @override
  State<_Dock> createState() => _DockState();
}

class _DockState extends State<_Dock> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tone = widget.tone;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: Obx(() {
        final cur = c.currentPage.value;
        final shown = (_drag ?? cur.toDouble()).round();
        const total = QuranMushafController.totalPages;
        final page = c.pages[shown];

        return Row(
          children: [
            // In a right-to-left book "next" is on the left.
            _RoundNav(
              icon: Icons.chevron_left_rounded,
              tooltip: 'next'.tr,
              enabled: cur < total,
              tone: tone,
              onTap: c.nextPage,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
                decoration: BoxDecoration(
                  gradient: tone.dark
                      ? const LinearGradient(colors: [Color(0xFF123527), Color(0xFF0C2419)])
                      : MejlisPalette.emeraldGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: MejlisPalette.emerald.withOpacity(0.30),
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
                        Text(
                          '${'page'.tr} $shown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          page != null
                              ? '${'juz'.tr} ${page.juzNumber}  ·  $shown / $total'
                              : '$shown / $total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    // RTL so page 1 sits on the right, matching the book.
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: MejlisPalette.gold,
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: MejlisPalette.gold,
                          overlayColor: MejlisPalette.gold.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          showValueIndicator: ShowValueIndicator.onDrag,
                        ),
                        child: Slider(
                          value: (_drag ?? cur.toDouble()).clamp(1.0, total.toDouble()),
                          min: 1,
                          max: total.toDouble(),
                          label: '$shown',
                          onChanged: (v) => setState(() => _drag = v),
                          onChangeEnd: (v) {
                            setState(() => _drag = null);
                            HapticFeedback.selectionClick();
                            c.jumpToPage(v.round());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _RoundNav(
              icon: Icons.chevron_right_rounded,
              tooltip: 'previous'.tr,
              enabled: cur > 1,
              tone: tone,
              onTap: c.previousPage,
            ),
          ],
        );
      }),
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

class _PageSkeleton extends StatefulWidget {
  final _Tone tone;
  const _PageSkeleton({required this.tone});

  @override
  State<_PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<_PageSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tone;
    final shape = MejlisPalette.gold.withOpacity(0.22);
    const widths = [1.0, 0.96, 1.0, 0.92, 1.0, 0.98, 0.9, 1.0, 0.95, 1.0, 0.93, 1.0, 0.97, 0.9, 0.55];

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Opacity(
        opacity: 0.45 + 0.55 * _c.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: t.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MejlisPalette.gold.withOpacity(0.35), width: 1.3),
            ),
            child: Column(
              children: [
                for (final w in widths)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: w,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: shape,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════ JUMP SHEET ═════════════════════════════

class _JumpSheet extends StatefulWidget {
  final QuranMushafController controller;
  const _JumpSheet({required this.controller});

  @override
  State<_JumpSheet> createState() => _JumpSheetState();
}

class _JumpSheetState extends State<_JumpSheet> {
  final _pageField = TextEditingController();
  final _surahField = TextEditingController();
  String _surahQuery = '';
  String? _pageError;

  @override
  void dispose() {
    _pageField.dispose();
    _surahField.dispose();
    super.dispose();
  }

  void _goToPage(int? page) {
    if (page == null || page < 1 || page > QuranMushafController.totalPages) {
      setState(() => _pageError = 'invalidPage'.tr);
      return;
    }
    widget.controller.jumpToPage(page);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final tone = _Tone.of(context, sepia: c.sepiaMode.value);
    final media = MediaQuery.of(context);
    final height = (media.size.height - media.viewInsets.bottom) * 0.85;

    final curPage = c.pages[c.currentPage.value];
    final curSurah = (curPage != null && curPage.ayahs.isNotEmpty) ? curPage.ayahs.first.surahNumber : -1;
    final curJuz = curPage?.juzNumber ?? -1;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: tone.bg,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: MejlisPalette.gold.withOpacity(0.45), width: 1.5),
        ),
        child: SizedBox(
          height: height,
          child: DefaultTabController(
            length: 3,
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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
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
                // pill tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tone.paper,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: MejlisPalette.gold.withOpacity(0.3)),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    splashBorderRadius: BorderRadius.circular(14),
                    indicator: BoxDecoration(
                      gradient: MejlisPalette.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: const Color(0xFF2A2104),
                    unselectedLabelColor: tone.inkSoft,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    tabs: [
                      Tab(height: 36, text: 'page'.tr),
                      Tab(height: 36, text: 'surah'.tr),
                      Tab(height: 36, text: 'juz'.tr),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: TabBarView(
                    children: [
                      _pageTab(tone),
                      _surahTab(tone, curSurah),
                      _juzTab(tone, curJuz),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── page ──
  Widget _pageTab(_Tone tone) {
    const quick = [1, 100, 200, 300, 400, 500, QuranMushafController.totalPages];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _pageField,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_pageError != null) setState(() => _pageError = null);
            },
            onSubmitted: (v) => _goToPage(int.tryParse(v)),
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: tone.accent),
            decoration: InputDecoration(
              hintText: '1 – ${QuranMushafController.totalPages}',
              hintStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: tone.inkSoft.withOpacity(0.5),
              ),
              errorText: _pageError,
              filled: true,
              fillColor: tone.paper,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: MejlisPalette.gold.withOpacity(0.35)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: MejlisPalette.gold, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final q in quick)
                ActionChip(
                  label: Text('$q'),
                  backgroundColor: MejlisPalette.gold.withOpacity(0.12),
                  side: BorderSide(color: MejlisPalette.gold.withOpacity(0.4)),
                  labelStyle: TextStyle(fontWeight: FontWeight.w800, color: tone.accent),
                  onPressed: () => _goToPage(q),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: MejlisPalette.gold,
                foregroundColor: const Color(0xFF2A2104),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () => _goToPage(int.tryParse(_pageField.text)),
              child: Text(
                'go'.tr,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── surah ──
  Widget _surahTab(_Tone tone, int curSurah) {
    final q = _surahQuery.trim().toLowerCase();
    final list = quranSurahNames.where((s) {
      if (q.isEmpty) return true;
      return s.english.toLowerCase().contains(q) ||
          s.arabic.contains(_surahQuery.trim()) ||
          '${s.number}'.startsWith(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _surahField,
            onChanged: (v) => setState(() => _surahQuery = v),
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
          child: list.isEmpty
              ? Center(child: Text('noResults'.tr, style: TextStyle(color: tone.inkSoft)))
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 20),
            itemExtent: 70,
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              final selected = s.number == curSurah;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    widget.controller.goToSurah(s.number);
                    Navigator.of(context).pop();
                  },
                  child: Container(
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
                          child: Text(
                            s.english,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: tone.ink,
                            ),
                          ),
                        ),
                        Text(
                          s.arabic,
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
          ),
        ),
      ],
    );
  }

  // ── juz ──
  Widget _juzTab(_Tone tone, int curJuz) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: standardJuzStartPages.length,
      itemBuilder: (context, index) {
        final juz = index + 1;
        final selected = juz == curJuz;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            widget.controller.goToJuz(juz);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: selected ? MejlisPalette.gold.withOpacity(0.14) : tone.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? MejlisPalette.gold : MejlisPalette.gold.withOpacity(0.2),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StarMedallion(
                  label: '$juz',
                  size: 44,
                  active: selected,
                  inkColor: tone.accent,
                ),
                const SizedBox(height: 6),
                Text(
                  '${'page'.tr} ${standardJuzStartPages[index]}',
                  style: TextStyle(fontSize: 11, color: tone.inkSoft, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════ SETTINGS SHEET ═════════════════════════════

class _MushafSettingsSheet extends GetView<QuranMushafController> {
  final ScrollController? scrollController;
  const _MushafSettingsSheet({this.scrollController});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, sc) => _MushafSettingsSheet(scrollController: sc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: dark ? const Color(0xFF0C1712) : const Color(0xFFFAF6EC),
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
                _translation(context, scheme, dark),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              controller.setFontSize((v + d).clamp(16.0, 32.0).toDouble());
            }

            return Row(
              children: [
                _StepButton(label: 'A', small: true, onTap: v > 16 ? () => step(-2) : null),
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
                      min: 16,
                      max: 32,
                      divisions: 8,
                      label: v.toStringAsFixed(0),
                      onChanged: controller.setFontSize,
                    ),
                  ),
                ),
                _StepButton(label: 'A', small: false, onTap: v < 32 ? () => step(2) : null),
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
                    paper: dark ? const Color(0xFF101C16) : const Color(0xFFFFFDF8),
                    ink: dark ? const Color(0xFFEDE7D6) : const Color(0xFF1C1C1C),
                    selected: !sepia,
                    onTap: () => controller.setSepiaMode(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PaperTile(
                    label: 'sepiaReadingMode'.tr,
                    paper: const Color(0xFFF3E7CE),
                    ink: const Color(0xFF3B2E1E),
                    selected: sepia,
                    onTap: () => controller.setSepiaMode(true),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _translation(BuildContext context, ColorScheme scheme, bool dark) {
    return _SectionCard(
      icon: Icons.translate_rounded,
      title: 'translation'.tr,
      dark: dark,
      child: Column(
        children: [
          Obx(
                () => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: MejlisPalette.gold,
              title: Text(
                'showTranslation'.tr,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'enableTranslationHint'.tr,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
              ),
              value: controller.showTranslation.value,
              onChanged: controller.setShowTranslation,
            ),
          ),
          const SizedBox(height: 6),
          Obx(() {
            final enabled = controller.showTranslation.value;
            final selected = controller.translationEdition.value;
            return AnimatedOpacity(
              opacity: enabled ? 1 : 0.4,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !enabled,
                child: Column(
                  children: [
                    for (final t in mushafAvailableTranslations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            controller.setTranslationEdition(t.identifier);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected == t.identifier
                                  ? MejlisPalette.gold.withOpacity(0.12)
                                  : scheme.surfaceContainerHighest.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected == t.identifier
                                    ? MejlisPalette.gold
                                    : Colors.transparent,
                                width: 1.3,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.displayName,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: selected == t.identifier
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                _CheckDot(active: selected == t.identifier),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final QuranMushafController controller;
  final bool dark;
  const _PreviewCard({required this.controller, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sepia = controller.sepiaMode.value && !dark;
      final paper = dark
          ? const Color(0xFF101C16)
          : (sepia ? const Color(0xFFF3E7CE) : const Color(0xFFFFFDF8));
      final ink = dark
          ? const Color(0xFFEDE7D6)
          : (sepia ? const Color(0xFF3B2E1E) : const Color(0xFF1C1C1C));
      final fs = controller.fontSize.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.55), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: MejlisPalette.gold.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MejlisPalette.gold.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const StarMedallion(size: 20, active: true),
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
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiriQuran(fontSize: fs * 1.05, height: 1.9, color: ink),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiriQuran(fontSize: fs, height: 1.9, color: ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool dark;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF101C16) : Colors.white,
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