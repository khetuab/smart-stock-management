import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/quran_mushaf_models.dart';
import '../../controllers/quran_mushaf_controller.dart';

/// A page-by-page "real mushaf" reader: 604 pages, 15 lines per page,
/// swiped right-to-left like a physical Arabic book.
///
/// See the doc comment on `layOutPageLines` in `quran_mushaf_models.dart`
/// for exactly what "15 lines" means here and its one known limitation:
/// page *boundaries* are exact (604 real mushaf pages); line breaks
/// *within* a page are an even word-count approximation, not a
/// pixel-identical reproduction of one specific printed mushaf.
class QuranMushafScreen extends GetView<QuranMushafController> {
  const QuranMushafScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E3),
      appBar: AppBar(
        title: Obx(() {
          final page = controller.pages[controller.currentPage.value];
          final surahName = (page != null && page.ayahs.isNotEmpty) ? page.ayahs.first.surahNameEnglish : '';
          return Text(surahName.isEmpty ? 'quran'.tr : surahName);
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'jumpTo'.tr,
            onPressed: () => _showJumpSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'readingSettings'.tr,
            onPressed: () => _MushafSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isBootstrapping.value) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return Column(
            children: [
              Expanded(
                // The classic "flip like an Arabic book" trick: an RTL
                // Directionality ancestor plus reverse:true means swiping
                // from the right edge toward the left moves forward
                // (page 1 -> 2 -> 3 ...), matching a physical mushaf.
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: PageView.builder(
                    controller: controller.pageController,
                    reverse: true,
                    itemCount: QuranMushafController.totalPages,
                    onPageChanged: controller.onPageChanged,
                    itemBuilder: (context, index) => _MushafPageView(pageNumber: index + 1),
                  ),
                ),
              ),
              _bottomBar(),
            ],
          );
        }),
      ),
    );
  }

  Widget _bottomBar() {
    return Obx(
          () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: controller.currentPage.value < QuranMushafController.totalPages ? controller.nextPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: Text('next'.tr),
            ),
            Text(
              '${'page'.tr} ${controller.currentPage.value} / ${QuranMushafController.totalPages}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: controller.currentPage.value > 1 ? controller.previousPage : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text('previous'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _showJumpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _JumpSheet(controller: controller),
    );
  }
}

// ---------------------------------------------------------------------
// One page
// ---------------------------------------------------------------------

class _MushafPageView extends GetView<QuranMushafController> {
  final int pageNumber;
  const _MushafPageView({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final page = controller.pages[pageNumber];
      final isLoading = controller.loadingPages.contains(pageNumber);
      final failed = controller.failedPages.contains(pageNumber);

      if (failed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 40),
              const SizedBox(height: 8),
              Text('failedToLoadQuranPage'.tr),
              const SizedBox(height: 8),
              TextButton(onPressed: () => controller.retryPage(pageNumber), child: Text('retry'.tr)),
            ],
          ),
        );
      }

      if (page == null || isLoading) {
        return const Center(child: CircularProgressIndicator.adaptive());
      }

      final sepia = controller.sepiaMode.value;
      final paperColor = sepia ? const Color(0xFFF3E7CE) : const Color(0xFFFFFDF8);
      final textColor = sepia ? const Color(0xFF3B2E1E) : const Color(0xFF1C1C1C);

      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        child: Container(
          decoration: BoxDecoration(
            color: paperColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.brown.withOpacity(0.35), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              _pageHeader(page, textColor),
              const Divider(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [for (final line in page.lines) _MushafLineWidget(line: line, textColor: textColor)],
                  ),
                ),
              ),
              const Divider(height: 12),
              Text('${'page'.tr} ${page.pageNumber}', style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
            ],
          ),
        ),
      );
    });
  }

  Widget _pageHeader(MushafPage page, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${'juz'.tr} ${page.juzNumber}', style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6))),
        Text(
          '${'page'.tr} ${page.pageNumber} / ${MushafPage.totalPages}',
          style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// One line
// ---------------------------------------------------------------------

class _MushafLineWidget extends GetView<QuranMushafController> {
  final MushafLine line;
  final Color textColor;
  const _MushafLineWidget({required this.line, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final fontSize = controller.fontSize.value;
      switch (line.kind) {
        case MushafLineKind.blank:
          return const SizedBox(height: 4);

        case MushafLineKind.bismillah:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiriQuran(fontSize: fontSize, color: textColor),
            ),
          );

        case MushafLineKind.surahBanner:
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: Colors.brown.withOpacity(0.4))),
            ),
            child: Text(
              line.bannerText ?? '',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiriQuran(fontSize: fontSize * 0.85, fontWeight: FontWeight.bold, color: textColor),
            ),
          );

        case MushafLineKind.text:
          return Text.rich(
            TextSpan(children: _buildSpans()),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiriQuran(fontSize: fontSize, height: 1.9, color: textColor),
          );
      }
    });
  }

  List<InlineSpan> _buildSpans() {
    final spans = <InlineSpan>[];
    for (final seg in line.segments) {
      spans.add(TextSpan(text: '${seg.words} '));
      if (seg.endsAyahHere) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _AyahEndMarker(number: seg.ayah.numberInSurah, textColor: textColor),
          ),
        ));
      }
    }
    return spans;
  }
}

class _AyahEndMarker extends StatelessWidget {
  final int number;
  final Color textColor;
  const _AyahEndMarker({required this.number, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: textColor.withOpacity(0.5), width: 1)),
      child: Text('$number', style: TextStyle(fontSize: 9, color: textColor)),
    );
  }
}

// ---------------------------------------------------------------------
// Jump-to sheet (page / surah / juz)
// ---------------------------------------------------------------------

class _JumpSheet extends StatelessWidget {
  final QuranMushafController controller;
  const _JumpSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final pageFieldController = TextEditingController();
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              TabBar(tabs: [Tab(text: 'page'.tr), Tab(text: 'surah'.tr), Tab(text: 'juz'.tr)]),
              Expanded(
                child: TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: pageFieldController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${'page'.tr} (1-${QuranMushafController.totalPages})',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              final page = int.tryParse(pageFieldController.text);
                              if (page != null) {
                                controller.jumpToPage(page);
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text('go'.tr),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      itemCount: quranSurahNames.length,
                      itemBuilder: (context, index) {
                        final entry = quranSurahNames[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${entry.number}')),
                          title: Text(entry.arabic, textDirection: TextDirection.rtl),
                          subtitle: Text(entry.english),
                          onTap: () {
                            controller.goToSurah(entry.number);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                    ListView.builder(
                      itemCount: standardJuzStartPages.length,
                      itemBuilder: (context, index) {
                        final juzNumber = index + 1;
                        return ListTile(
                          leading: CircleAvatar(child: Text('$juzNumber')),
                          title: Text('${'juz'.tr} $juzNumber'),
                          subtitle: Text('${'page'.tr} ~${standardJuzStartPages[index]}'),
                          onTap: () {
                            controller.goToJuz(juzNumber);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Settings sheet
// ---------------------------------------------------------------------

class _MushafSettingsSheet extends GetView<QuranMushafController> {
  const _MushafSettingsSheet();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _MushafSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('readingSettings'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('arabicFontSize'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
            Obx(() => Slider(
              value: controller.fontSize.value,
              min: 16,
              max: 32,
              divisions: 8,
              label: controller.fontSize.value.toStringAsFixed(0),
              onChanged: controller.setFontSize,
            )),
            Obx(() => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('showTranslation'.tr),
              value: controller.showTranslation.value,
              onChanged: controller.setShowTranslation,
            )),
            Obx(() => AnimatedOpacity(
              opacity: controller.showTranslation.value ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !controller.showTranslation.value,
                child: DropdownButtonFormField<String>(
                  initialValue: controller.translationEdition.value,
                  decoration: InputDecoration(
                    labelText: 'translation'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: mushafAvailableTranslations
                      .map((t) => DropdownMenuItem(value: t.identifier, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) controller.setTranslationEdition(value);
                  },
                ),
              ),
            )),
            Obx(() => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('sepiaReadingMode'.tr),
              value: controller.sepiaMode.value,
              onChanged: controller.setSepiaMode,
            )),
          ],
        ),
      ),
    );
  }
}