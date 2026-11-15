// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// /// ─────────────────────────────────────────────────────────────────────────
// ///  ETHIOSADAT MEJLIS — "ARABIAN MEJLIS" DESIGN SYSTEM
// ///  Emerald & Gold: deep emerald fabrics, royal gold ornament, ivory silk.
// ///
// ///  API compatibility notes:
// ///   • AppTheme.light({Color? seedColor}) / AppTheme.dark({Color? seedColor})
// ///     signatures are unchanged — the Setup wizard + ThemeController keep
// ///     working exactly as before (owner's picked seed still overrides).
// ///   • defaultSeed is now the house DARK GREEN.
// /// ─────────────────────────────────────────────────────────────────────────
// class AppTheme {
//   /// House dark green — the main brand color of the whole app.
//   static const Color defaultSeed = Color(0xFF0A4F34);
//
//   // Semantic colors (unchanged API)
//   static const Color success = Color(0xFF16A34A);
//   static const Color error = Color(0xFFDC2626);
//   static const Color warning = Color(0xFFEA580C);
//   static const Color info = Color(0xFF0891B2);
//
//   static ThemeData light({Color? seedColor}) {
//     //final primary = seedColor ?? defaultSeed;
//     final primary = defaultSeed;
//     final gold = MejlisPalette.gold;
//     final scheme = ColorScheme.light(
//       primary: primary,
//       secondary: gold,
//       tertiary: MejlisPalette.goldDark,
//       surface: const Color(0xFFFFFDF7), // warm ivory surface
//       background: const Color(0xFFFAF6ED), // sand-silk canvas
//       error: error,
//       onPrimary: Colors.white,
//       onSecondary: const Color(0xFF2A2104),
//       onTertiary: Colors.white,
//       onSurface: const Color(0xFF1C2420),
//       onBackground: const Color(0xFF1C2420),
//       onError: Colors.white,
//       surfaceContainerHighest: const Color(0xFFF2EBDC),
//     );
//
//     final textTheme = GoogleFonts.poppinsTextTheme(
//       ThemeData(brightness: Brightness.light, colorScheme: scheme).textTheme,
//     );
//
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       colorScheme: scheme,
//       textTheme: textTheme,
//
//       appBarTheme: AppBarTheme(
//         backgroundColor: primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         titleTextStyle: GoogleFonts.marcellus(
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//           letterSpacing: 0.4,
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//
//       cardTheme: CardThemeData(
//         color: const Color(0xFFFFFDF7),
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(18),
//           side: BorderSide(color: gold.withOpacity(0.35), width: 1),
//         ),
//         clipBehavior: Clip.antiAlias,
//       ),
//
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: const Color(0xFFF8F4EA),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFFE4D9BF)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFFE4D9BF)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: primary, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: error),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         labelStyle: GoogleFonts.poppins(color: const Color(0xFF7A7460)),
//       ),
//
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primary,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
//           elevation: 0,
//         ),
//       ),
//
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: primary,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           side: BorderSide(color: primary.withOpacity(0.3)),
//           textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
//         ),
//       ),
//
//       bottomNavigationBarTheme: BottomNavigationBarThemeData(
//         backgroundColor: const Color(0xFFFFFDF7),
//         selectedItemColor: primary,
//         unselectedItemColor: const Color(0xFFA79E85),
//         selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
//         unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
//         elevation: 10,
//         type: BottomNavigationBarType.fixed,
//       ),
//
//       chipTheme: ChipThemeData(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: BorderSide(color: gold.withOpacity(0.35)),
//       ),
//
//       snackBarTheme: SnackBarThemeData(
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//
//       scaffoldBackgroundColor: const Color(0xFFFAF6ED),
//       dividerTheme: const DividerThemeData(
//         color: Color(0xFFE7DEC8),
//         thickness: 1,
//         space: 0,
//       ),
//     );
//   }
//
//   static ThemeData dark({Color? seedColor}) {
//     //final primary = seedColor ?? defaultSeed;
//     final primary = defaultSeed;
//     final gold = MejlisPalette.goldBright;
//     final scheme = ColorScheme.dark(
//       // lifted just enough to stay a readable DARK GREEN on dark surfaces
//       primary: HSLColor.fromColor(primary).withLightness(0.32).toColor(),
//       secondary: gold,
//       tertiary: const Color(0xFF8FBFA9),
//       surface: const Color(0xFF12201B), // deep emerald surface
//       background: const Color(0xFF0A120E), // night-emerald canvas
//       error: error,
//       onPrimary: Colors.white,
//       onSecondary: const Color(0xFF241D03),
//       onTertiary: const Color(0xFF06110C),
//       onSurface: const Color(0xFFEDE7D6),
//       onBackground: const Color(0xFFEDE7D6),
//       onError: Colors.white,
//       surfaceContainerHighest: const Color(0xFF182922),
//     );
//
//     final textTheme = GoogleFonts.poppinsTextTheme(
//       ThemeData(brightness: Brightness.dark, colorScheme: scheme).textTheme,
//     );
//
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       colorScheme: scheme,
//       textTheme: textTheme,
//
//       appBarTheme: AppBarTheme(
//         backgroundColor: const Color(0xFF0D1813),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         centerTitle: false,
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         titleTextStyle: GoogleFonts.marcellus(
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//           letterSpacing: 0.4,
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//
//       cardTheme: CardThemeData(
//         color: const Color(0xFF12201B),
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(18),
//           side: BorderSide(color: gold.withOpacity(0.22), width: 1),
//         ),
//         clipBehavior: Clip.antiAlias,
//       ),
//
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: const Color(0xFF0F1B16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFF24382F)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: Color(0xFF24382F)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: gold, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: error),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         labelStyle: GoogleFonts.poppins(color: const Color(0xFF8FA096)),
//       ),
//
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: scheme.primary,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
//           elevation: 0,
//         ),
//       ),
//
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: gold,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           side: BorderSide(color: gold.withOpacity(0.4)),
//           textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
//         ),
//       ),
//
//       bottomNavigationBarTheme: BottomNavigationBarThemeData(
//         backgroundColor: const Color(0xFF0D1813),
//         selectedItemColor: gold,
//         unselectedItemColor: const Color(0xFF5F7A6C),
//         selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
//         unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
//         elevation: 10,
//         type: BottomNavigationBarType.fixed,
//       ),
//
//       chipTheme: ChipThemeData(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: BorderSide(color: gold.withOpacity(0.3)),
//       ),
//
//       snackBarTheme: SnackBarThemeData(
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//
//       scaffoldBackgroundColor: const Color(0xFF0A120E),
//       dividerTheme: const DividerThemeData(
//         color: Color(0xFF24382F),
//         thickness: 1,
//         space: 0,
//       ),
//     );
//   }
//
//   static Color colorFromHex(String hexString) {
//     final buffer = StringBuffer();
//     if (hexString.length == 6 || hexString.length == 7) {
//       buffer.write('FF');
//       buffer.write(hexString.replaceAll('#', ''));
//     }
//     return Color(int.parse(buffer.toString(), radix: 16));
//   }
//
//   static String colorToHex(Color color) {
//     return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
//   }
// }
//
// /// ─────────────────────────────────────────────────────────────────────────
// ///  MejlisPalette — the house colours of the Arabian Mejlis design language.
// ///  Reference these instead of raw hex in feature screens so light/dark and
// ///  future rebrands stay one-line changes.
// /// ─────────────────────────────────────────────────────────────────────────
// class MejlisPalette {
//   MejlisPalette._();
//
//   // Fabrics (dark green family)
//   static const Color emerald = Color(0xFF0A5C3E);
//   static const Color emeraldDeep = Color(0xFF063D28);
//   static const Color emeraldNight = Color(0xFF0A120E);
//   static const Color ivory = Color(0xFFFFFDF7);
//   static const Color sand = Color(0xFFFAF6ED);
//
//   // Golds
//   static const Color gold = Color(0xFFC9A227);
//   static const Color goldLight = Color(0xFFE7C868);
//   static const Color goldBright = Color(0xFFE3C567);
//   static const Color goldDark = Color(0xFF9A7B1E);
//
//   /// Signature royal-gold gradient (used for buttons, rings, markers).
//   static const LinearGradient goldGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [Color(0xFFE7C868), Color(0xFFC9A227), Color(0xFF9A7B1E)],
//     stops: [0.0, 0.55, 1.0],
//   );
//
//   /// Dark green header gradient.
//   static const LinearGradient emeraldGradient = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [Color(0xFF0D6B47), Color(0xFF0A4F34), Color(0xFF063D28)],
//     stops: [0.0, 0.5, 1.0],
//   );
//
//   /// Dark-mode friendly gold gradient.
//   static const LinearGradient goldGradientDark = LinearGradient(
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//     colors: [Color(0xFFF3D98A), Color(0xFFE3C567), Color(0xFFB08F24)],
//     stops: [0.0, 0.55, 1.0],
//   );
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// ETHIOSADAT MEJLIS — WHITE & DARK BLUE DESIGN SYSTEM
/// Royal navy, clean white, and elegant silver-blue accents.
/// Variable names and public API remain unchanged.
/// ─────────────────────────────────────────────────────────────────────────

class AppTheme {
  /// Main brand color.
  static const Color defaultSeed = Color(0xFF142B4F);

  // Semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFEA580C);
  static const Color info = Color(0xFF0284C7);

  static ThemeData light({Color? seedColor}) {
    final primary = defaultSeed;
    final gold = MejlisPalette.gold;

    final scheme = ColorScheme.light(
      primary: primary,
      secondary: gold,
      tertiary: MejlisPalette.goldDark,
      surface: const Color(0xFFFFFFFF),
      background: const Color(0xFFF4F7FC),
      error: error,
      onPrimary: Colors.white,
      onSecondary: const Color(0xFFFFFFFF),
      onTertiary: Colors.white,
      onSurface: const Color(0xFF17243A),
      onBackground: const Color(0xFF17243A),
      onError: Colors.white,
      surfaceContainerHighest: const Color(0xFFEAF0F8),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(
        brightness: Brightness.light,
        colorScheme: scheme,
      ).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.marcellus(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: gold.withOpacity(0.25),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDCE5F1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDCE5F1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF718096),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: primary.withOpacity(0.3),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
        ),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(
          color: gold.withOpacity(0.3),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      scaffoldBackgroundColor: const Color(0xFFF4F7FC),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE1E8F0),
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData dark({Color? seedColor}) {
    final primary = defaultSeed;
    final gold = MejlisPalette.goldBright;

    final scheme = ColorScheme.dark(
      primary: const Color(0xFF6D9FE8),
      secondary: gold,
      tertiary: const Color(0xFF9DBCEB),
      surface: const Color(0xFF17243A),
      background: const Color(0xFF0B1424),
      error: error,
      onPrimary: const Color(0xFF081426),
      onSecondary: const Color(0xFF101B2D),
      onTertiary: const Color(0xFF081426),
      onSurface: const Color(0xFFF1F5FB),
      onBackground: const Color(0xFFF1F5FB),
      onError: Colors.white,
      surfaceContainerHighest: const Color(0xFF22334D),
    );

    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(
        brightness: Brightness.dark,
        colorScheme: scheme,
      ).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF101D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.marcellus(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF17243A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: gold.withOpacity(0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101D32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2B3D58),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2B3D58),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF9AAAC0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: const Color(0xFF081426),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: scheme.primary.withOpacity(0.4),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF101D32),
        selectedItemColor: scheme.primary,
        unselectedItemColor: const Color(0xFF71839D),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
        ),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(
          color: gold.withOpacity(0.3),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      scaffoldBackgroundColor: const Color(0xFF0B1424),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF2B3D58),
        thickness: 1,
        space: 0,
      ),
    );
  }

  static Color colorFromHex(String hexString) {
    final buffer = StringBuffer();

    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('FF');
      buffer.write(hexString.replaceAll('#', ''));
    }

    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// MejlisPalette — white and royal dark-blue design language.
/// Existing variable names are preserved.
/// ─────────────────────────────────────────────────────────────────────────

class MejlisPalette {
  MejlisPalette._();

  // Main color family
  static const Color emerald = Color(0xFF1B3760);
  static const Color emeraldDeep = Color(0xFF102442);
  static const Color emeraldNight = Color(0xFF0B1424);
  static const Color ivory = Color(0xFFFFFFFF);
  static const Color sand = Color(0xFFF4F7FC);

  // Blue and silver accents
  static const Color gold = Color(0xFF6D9FE8);
  static const Color goldLight = Color(0xFFA9C8F5);
  static const Color goldBright = Color(0xFF8AB5F0);
  static const Color goldDark = Color(0xFF416FAE);

  /// Signature silver-blue gradient.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA9C8F5),
      Color(0xFF6D9FE8),
      Color(0xFF416FAE),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Dark-blue header gradient.
  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF294C7B),
      Color(0xFF1B3760),
      Color(0xFF102442),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Dark-mode friendly blue gradient.
  static const LinearGradient goldGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC4DAFA),
      Color(0xFF8AB5F0),
      Color(0xFF5B8BCB),
    ],
    stops: [0.0, 0.55, 1.0],
  );
}
