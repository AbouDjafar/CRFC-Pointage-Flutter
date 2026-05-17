import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CrfcColors {
  static const Color primary = Color(0xFFC0771B);
  static const Color primaryDark = Color(0xFFE6A26A);
  static const Color background = Color(0xFFE5F2E4);
  static const Color backgroundDark = Color(0xFF191C19);
  static const Color surface = Color(0xFFF7FCF7);
  static const Color surfaceDark = Color(0xFF282D28);
  static const Color secondaryBackground = Color(0xFFD9EBD8);
  static const Color secondaryBackgroundDark = Color(0xFF232622);
  static const Color divider = Color(0xFFCCE0CB);
  static const Color dividerDark = Color(0xFF373D36);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textDark = Color(0xFFE5F2E4);
  static const Color muted = Color(0xFF545454);
  static const Color mutedDark = Color(0xFFA6B8A5);
  static const Color accent = Color(0xFF4A5D7C);
  static const Color accentBlue = Color(0xFF2E5894);
  static const Color success = Color(0xFF4A7C59);
  static const Color warning = Color(0xFFC87941);
  static const Color error = Color(0xFFB23B3B);
  static const Color splashTop = Color(0xFF1E3A5F);
  static const Color splashBottom = Color(0xFF2A5298);
  static const Color splashOrange = Color(0xFFF97316);
  static const Color splashOrangeDeep = Color(0xFFEA580C);
}

class CrfcSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class CrfcRadii {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(6));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(12));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(18));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

ThemeData buildLightTheme() {
  final textTheme = GoogleFonts.sourceSans3TextTheme().copyWith(
    displayLarge: GoogleFonts.sourceSans3(
      fontSize: 56,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    displayMedium: GoogleFonts.sourceSans3(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    displaySmall: GoogleFonts.sourceSans3(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    headlineLarge: GoogleFonts.sourceSans3(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineMedium: GoogleFonts.sourceSans3(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.sourceSans3(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: GoogleFonts.sourceSans3(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: GoogleFonts.sourceSans3(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleSmall: GoogleFonts.sourceSans3(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: GoogleFonts.sourceSans3(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.7,
    ),
    bodyMedium: GoogleFonts.sourceSans3(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.7,
    ),
    bodySmall: GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.7,
    ),
    labelLarge: GoogleFonts.sourceSans3(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelMedium: GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelSmall: GoogleFonts.sourceSans3(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
  );

  final scheme = ColorScheme.fromSeed(
    seedColor: CrfcColors.primary,
    brightness: Brightness.light,
    surface: CrfcColors.surface,
  );

  return ThemeData(
    colorScheme: scheme.copyWith(
      primary: CrfcColors.primary,
      secondary: CrfcColors.accent,
      surface: CrfcColors.surface,
      onSurface: CrfcColors.text,
      error: CrfcColors.error,
    ),
    scaffoldBackgroundColor: CrfcColors.background,
    textTheme: textTheme,
    useMaterial3: true,
    dividerColor: CrfcColors.divider,
    canvasColor: CrfcColors.surface,
    cardTheme: const CardThemeData(
      color: CrfcColors.surface,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: CrfcRadii.lg),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: CrfcRadii.md,
        borderSide: const BorderSide(color: CrfcColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: CrfcRadii.md,
        borderSide: const BorderSide(color: Color(0xFFB7D3B5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: CrfcRadii.md,
        borderSide: const BorderSide(color: CrfcColors.accentBlue, width: 1.4),
      ),
      hintStyle: textTheme.bodyLarge?.copyWith(color: CrfcColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CrfcColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: const RoundedRectangleBorder(borderRadius: CrfcRadii.md),
        textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CrfcColors.text,
        side: const BorderSide(color: CrfcColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: CrfcRadii.md),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CrfcColors.surface,
      selectedItemColor: CrfcColors.text,
      unselectedItemColor: CrfcColors.muted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = buildLightTheme();
  final textTheme = GoogleFonts.sourceSans3TextTheme().apply(
    bodyColor: CrfcColors.textDark,
    displayColor: CrfcColors.textDark,
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.dark,
      primary: CrfcColors.primaryDark,
      surface: CrfcColors.surfaceDark,
      onSurface: CrfcColors.textDark,
      error: const Color(0xFFE67A7A),
    ),
    scaffoldBackgroundColor: CrfcColors.backgroundDark,
    canvasColor: CrfcColors.surfaceDark,
    dividerColor: CrfcColors.dividerDark,
    cardTheme: const CardThemeData(
      color: CrfcColors.surfaceDark,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: CrfcRadii.lg),
    ),
    textTheme: textTheme,
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: CrfcColors.secondaryBackgroundDark,
      hintStyle: textTheme.bodyLarge?.copyWith(color: CrfcColors.mutedDark),
      enabledBorder: OutlineInputBorder(
        borderRadius: CrfcRadii.md,
        borderSide: const BorderSide(color: CrfcColors.dividerDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: CrfcRadii.md,
        borderSide: const BorderSide(color: CrfcColors.primaryDark, width: 1.4),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: CrfcColors.surfaceDark,
      selectedItemColor: CrfcColors.textDark,
      unselectedItemColor: CrfcColors.mutedDark,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
