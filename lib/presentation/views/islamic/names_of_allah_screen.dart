import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/names_of_allah_data.dart';
import '../../widgets/mejlis_kit.dart';

/// Asma-ul Husna — the 99 Beautiful Names of Allah, as an elegant gold
/// arabesque grid. Tap any name to expand it in a bottom sheet with the
/// Arabic calligraphy, transliteration and meaning.
class NamesOfAllahScreen extends StatelessWidget {
  const NamesOfAllahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                'namesOfAllah'.tr,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Center(child: OrnamentDivider(width: 170)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final n = kNamesOfAllah[index];
                  return _NameTile(name: n);
                },
                childCount: kNamesOfAllah.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameTile extends StatelessWidget {
  final NameOfAllah name;
  const _NameTile({required this.name});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [Color(0xFF1B3760), Color(0xFF102442)])
              : const LinearGradient(colors: [Color(0xFFFFFDF7), Color(0xFFFBF5E8)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: MejlisPalette.goldGradient,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${name.number}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2A2104),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                name.arabic,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark ? MejlisPalette.goldBright : MejlisPalette.emeraldDeep,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name.transliteration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: MejlisPalette.goldDark,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            Color(0xFF1B3760),
            Color(0xFF102442),
          ])
              : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFDF7), Color(0xFFFBF5E8)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: MejlisPalette.gold.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: MejlisPalette.gold.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(gradient: MejlisPalette.goldGradient, shape: BoxShape.circle),
              child: Text(
                '${name.number}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2A2104)),
              ),
            ),
            const SizedBox(height: 18),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                name.arabic,
                style: GoogleFonts.amiri(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? MejlisPalette.goldBright
                      : MejlisPalette.emeraldDeep,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name.transliteration,
              style: GoogleFonts.marcellus(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: MejlisPalette.goldDark,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name.meaning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            const OrnamentDivider(width: 180),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
