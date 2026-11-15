import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/themes/app_theme.dart';
import '../../../data/services/shared_preferences_service.dart';
import '../../../localization/locale_controller.dart';
import '../../widgets/mejlis_kit.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  FIRST-RUN LANGUAGE SELECTION
///
///  Shown once — before anything else — the very first time the app runs.
///  Four illustrated language cards (English / አማርኛ / العربية / Afaan
///  Oromoo). The choice is persisted, applied instantly via GetX, and the
///  user flows on to the normal destination (customer home / dashboard).
/// ─────────────────────────────────────────────────────────────────────────
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  static const String _chosenKey = 'languageChosen';

  static Future<bool> isNeeded(SharedPreferencesService prefs) async {
    return prefs.getBool(_chosenKey) != true;
  }

  Future<void> _choose(BuildContext context, String languageName) async {
    final prefs = SharedPreferencesService();
    await prefs.setBool(_chosenKey, true);

    // Apply instantly app-wide (LocaleController persists as well).
    try {
      await LocaleController.to.setLocale(languageName);
    } catch (_) {}

    // Then continue to wherever this device belongs.
    final isLoggedIn = prefs.isLoggedIn();
    final role = prefs.getRole();
    if (isLoggedIn && role == 'admin') {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.customerHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = const [
      _LangCard(
        name: 'English',
        native: 'Welcome',
        font: null,
      ),
      _LangCard(
        name: 'Amharic',
        native: 'እንኳን ደህና መጡ',
        font: null,
      ),
      _LangCard(
        name: 'Arabic',
        native: 'أهلاً وسهلاً',
        font: 'amiri',
      ),
      _LangCard(
        name: 'Oromo',
        native: 'Baga nagaan dhuftan',
        font: null,
      ),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Emerald night background
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B3760),
                  Color(0xFF091426),
                ],
                    )
                  : MejlisPalette.emeraldGradient,
            ),
          ),
          CustomPaint(painter: StarFieldPainter()),
          Positioned.fill(
            child: CustomPaint(painter: ArabesquePainter(lineColor: Colors.white, opacity: 0.06)),
          ),
          Positioned(
            top: 40,
            right: 30,
            child: HangingLantern(size: 42),
          ),
          Positioned(
            top: 90,
            left: 34,
            child: HangingLantern(size: 30, period: const Duration(seconds: 5)),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -30,
            height: 190,
            child: CustomPaint(
              painter: MosqueSkylinePainter(
                silhouette: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                glow: Colors.white,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emblem
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: MejlisPalette.goldGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: MejlisPalette.gold.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chair_rounded, color: Color(0xFF2A2104), size: 42),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Ethio Sadat Mejlis',
                      style: GoogleFonts.marcellus(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Arabian Mejlis · Sofas & Beds',
                      style: TextStyle(
                        color: MejlisPalette.goldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
                    const SizedBox(height: 10),
                    Text(
                      'chooseLanguage'.tr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 500.ms),
                    const SizedBox(height: 10),
                    const OrnamentDivider(width: 200),
                    const SizedBox(height: 22),

                    // Language cards
                    ...languages.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildLangButton(context, entry.value, entry.key),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'youCanChangeLater'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, _LangCard l, int index) {
    Widget label = Text(
      l.native,
      style: l.font == 'amiri'
          ? GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)
          : TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
    );

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _choose(context, l.name),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MejlisPalette.gold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: MejlisPalette.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFF2A2104), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(child: label),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (350 + index * 90).ms, duration: 420.ms).slideX(
          begin: 0.08,
          end: 0,
          delay: (350 + index * 90).ms,
          duration: 420.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _LangCard {
  final String name; // LocaleController key
  final String native;
  final String? font;
  const _LangCard({required this.name, required this.native, this.font});
}
