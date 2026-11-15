import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/islamic_controller.dart';
import '../../widgets/mejlis_kit.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/azkar_data.dart';
import '../../../localization/locale_controller.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  AZKAR — authentic morning / evening / after-prayer / sleeping adhkar.
///
///  Each zikr shows the Arabic (Amiri Quran type), a transliteration, and
///  the meaning in the app language (English or Amharic; Arabic builds show
///  the Arabic itself). A gold ring counter counts repetitions and fills
///  toward the sunnah count, with a soft haptic tick per tap.
/// ─────────────────────────────────────────────────────────────────────────

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final IslamicController _controller = IslamicController.to;
  int _categoryIndex = 0;
  final List<int> _counts = [];
  final List<bool> _done = [];

  AzkarCategory get _category => kAzkarCategories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    _resetCounters();
  }

  void _resetCounters() {
    _counts
      ..clear()
      ..addAll(_category.items.map((z) => z.count));
    _done
      ..clear()
      ..addAll(_category.items.map((_) => false));
  }

  void _onTapCount(int index) {
    if (_done[index]) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_counts[index] > 0) _counts[index]--;
      if (_counts[index] == 0) _done[index] = true;
    });
  }

  String _meaningFor(Zikr z) {
    final code = LocaleController.to.locale.value.languageCode;
    switch (code) {
      case 'ar':
        return z.arabic; // Arabic build: no separate translation needed
      case 'am':
        return z.am;
      default:
        return z.en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completed = _done.where((d) => d).length;
    final total = _category.items.length;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: scheme.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
              title: Text(
                'azkar'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                ),
              ),
              background: const MejlisHeaderBackground(showSkyline: false),
            ),
          ),

          // Category chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kAzkarCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _categoryIndex;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _categoryIndex = i;
                        _resetCounters();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: selected ? MejlisPalette.goldGradient : null,
                          color: selected
                              ? null
                              : isDark
                                  ? scheme.surfaceContainerHigh
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: selected ? Colors.transparent : MejlisPalette.gold.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          _categoryLabel(kAzkarCategories[i].id).tr,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? const Color(0xFF2A2104) : scheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Progress line
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: MejlisPalette.gold),
                  const SizedBox(width: 6),
                  Text(
                    '$completed / $total ${'completed'.tr}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          // Zikr cards
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final z = _category.items[index];
                  return _ZikrCard(
                    zikr: z,
                    remaining: _counts[index],
                    done: _done[index],
                    onTap: () => _onTapCount(index),
                    meaning: _meaningFor(z),
                  );
                },
                childCount: _category.items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String id) {
    switch (id) {
      case 'morning':
        return 'morningAzkar'.tr;
      case 'evening':
        return 'eveningAzkar'.tr;
      case 'afterPrayer':
        return 'afterPrayerAzkar'.tr;
      case 'sleeping':
        return 'sleepingAzkar'.tr;
      default:
        return id;
    }
  }
}

class _ZikrCard extends StatelessWidget {
  final Zikr zikr;
  final int remaining;
  final bool done;
  final VoidCallback onTap;
  final String meaning;

  const _ZikrCard({
    required this.zikr,
    required this.remaining,
    required this.done,
    required this.onTap,
    required this.meaning,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: done ? 0.75 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF1B3760), Color(0xFF102442)])
                : const LinearGradient(colors: [Color(0xFFFFFDF7), Color(0xFFFBF5E8)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: done ? MejlisPalette.emerald.withOpacity(0.6) : MejlisPalette.gold.withOpacity(0.35),
              width: done ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    zikr.arabic,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 21,
                      height: 1.9,
                      fontWeight: FontWeight.w600,
                      color: done ? MejlisPalette.emerald : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Transliteration
                Text(
                  zikr.transliteration,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: MejlisPalette.goldDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Meaning
                Text(
                  meaning,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (zikr.virtueEn.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    zikr.virtueEn.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: scheme.onSurfaceVariant.withOpacity(0.75),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CircularProgressIndicator(
                              value: zikr.count == 0 ? 0 : (zikr.count - remaining) / zikr.count,
                              strokeWidth: 4,
                              backgroundColor: MejlisPalette.gold.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                done ? MejlisPalette.emerald : MejlisPalette.gold,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            done ? '✓' : '$remaining',
                            style: TextStyle(
                              fontSize: done ? 20 : 16,
                              fontWeight: FontWeight.w900,
                              color: done ? MejlisPalette.emerald : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      done ? 'zikrComplete'.tr : 'tapToCount'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: done ? MejlisPalette.emerald : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (zikr.count > 1 && !done) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${zikr.count}x)',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
