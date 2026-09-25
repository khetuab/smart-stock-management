import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/models/quran_page_model.dart';
import '../../controllers/quran_page_controller.dart';
import '../../widgets/app_kits_collection.dart';
import '../../widgets/quran_settings_sheet.dart';

class QuranReaderScreen extends GetView<QuranReaderController> {
  const QuranReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          QuranSurahMeta? meta;
          for (final s in controller.surahList) {
            if (s.number == controller.currentSurah.value) {
              meta = s;
              break;
            }
          }
          return Text(meta?.name ?? '${'surah'.tr} ${controller.currentSurah.value}');
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'jumpTo'.tr,
            onPressed: () => _showSurahPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'readingSettings'.tr,
            onPressed: () => QuranSettingsSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: Obx(_buildBody)),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isBootstrapping.value) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (controller.errorMessage.value.isNotEmpty && controller.ayahs.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.wifi_off_rounded,
          title: 'somethingWentWrong'.tr,
          subtitle: controller.errorMessage.value,
          onAction: () {TextButton(
            onPressed: controller.retry,
            child: Text('retry'.tr),
          );}
        ),
      );
    }

    if (controller.isLoading.value && controller.ayahs.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      // Keying by surah forces a brand-new scroll state on surah change,
      // so `initialScrollIndex` is always honored instead of a stale
      // scroll position bleeding over from the previous surah.
      child: ScrollablePositionedList.builder(
        key: ValueKey('surah_${controller.currentSurah.value}'),
        itemScrollController: controller.itemScrollController,
        itemPositionsListener: controller.itemPositionsListener,
        initialScrollIndex: controller.initialAyahIndex.value,
        itemCount: controller.ayahs.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => _AyahBlock(ayah: controller.ayahs[index]),
      ),
    );
  }

  Widget _bottomBar() {
    return Obx(
          () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: controller.currentSurah.value > 1 ? controller.previousSurah : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: Text('previous'.tr),
            ),
            Text(
              '${'surah'.tr} ${controller.currentSurah.value} / ${QuranReaderController.totalSurahs}',
              style: const TextStyle(fontSize: 13),
            ),
            TextButton.icon(
              onPressed: controller.currentSurah.value < QuranReaderController.totalSurahs
                  ? controller.nextSurah
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
              label: Text('next'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _showSurahPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SurahPickerSheet(controller: controller),
    );
  }
}

class _SurahPickerSheet extends StatelessWidget {
  final QuranReaderController controller;
  const _SurahPickerSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Obx(() {
          final surahs = controller.surahList;
          if (surahs.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: surahs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = surahs[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${s.number}')),
                title: Text(s.name, textDirection: TextDirection.rtl),
                subtitle: Text('${s.englishName} · ${s.numberOfAyahs} ${'ayahs'.tr}'),
                onTap: () {
                  Navigator.of(context).pop();
                  controller.goToSurah(s.number);
                },
              );
            },
          );
        }),
      ),
    );
  }
}

class _AyahBlock extends GetView<QuranReaderController> {
  final QuranAyah ayah;
  const _AyahBlock({required this.ayah});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final sepia = controller.sepiaMode.value;
      final textColor = sepia ? const Color(0xFF3B2E1E) : scheme.onSurface;

      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ayah.numberInSurah == 1) _surahBanner(ayah.surahName),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${ayah.text} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _AyahMarker(number: ayah.numberInSurah),
                  ),
                ],
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiriQuran(
                fontSize: controller.fontSize.value,
                height: 2.1,
                color: textColor,
              ),
            ),
            if (controller.showTranslation.value &&
                ayah.translation != null &&
                ayah.translation!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  ayah.translation!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.75)),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _surahBanner(String surahName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Colors.brown.withOpacity(0.4))),
      ),
      child: Text(
        surahName,
        style: GoogleFonts.amiriQuran(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AyahMarker extends StatelessWidget {
  final int number;
  const _AyahMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.brown.withOpacity(0.6), width: 1),
      ),
      child: Text('$number', style: const TextStyle(fontSize: 11)),
    );
  }
}