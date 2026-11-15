import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/models/azkar_data.dart';
import '../../widgets/mejlis_kit.dart';

/// Salawat (blessings upon the Prophet ﷺ) with gold ring counters.
/// Same interaction language as the Azkar screen — tap to count, ring
/// fills to the sunnah count, gentle haptic per tap.
class SalawatScreen extends StatefulWidget {
  const SalawatScreen({super.key});

  @override
  State<SalawatScreen> createState() => _SalawatScreenState();
}

class _SalawatScreenState extends State<SalawatScreen> {
  late List<int> _counts;
  late List<bool> _done;

  @override
  void initState() {
    super.initState();
    _counts = kSalawat.map((s) => s.count).toList();
    _done = kSalawat.map((_) => false).toList();
  }

  void _onTap(int i) {
    if (_done[i]) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_counts[i] > 0) _counts[i]--;
      if (_counts[i] == 0) _done[i] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'salawat'.tr,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'salawatIntro'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = kSalawat[index];
                  return _SalawatCard(
                    salawat: s,
                    remaining: _counts[index],
                    done: _done[index],
                    onTap: () => _onTap(index),
                  );
                },
                childCount: kSalawat.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalawatCard extends StatelessWidget {
  final Zikr salawat;
  final int remaining;
  final bool done;
  final VoidCallback onTap;

  const _SalawatCard({
    required this.salawat,
    required this.remaining,
    required this.done,
    required this.onTap,
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
                ?const LinearGradient(
              colors: [
                Color(0xFF1B3760),
                Color(0xFF102442),
              ],
            )
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
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    salawat.arabic,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      height: 1.9,
                      fontWeight: FontWeight.w600,
                      color: done ? MejlisPalette.emerald : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  salawat.transliteration,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: MejlisPalette.goldDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  salawat.en.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
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
                              value: salawat.count == 0 ? 0 : (salawat.count - remaining) / salawat.count,
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
