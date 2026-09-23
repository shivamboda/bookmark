import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Central theme builder for "Bookmark".
///
/// Features warm creamy paper backgrounds, soft pink-tinted shadows,
/// rounded 20px cards, and romantic botanical typography pairing:
/// Playfair Display (editorial serif) + Nunito (friendly rounded sans).
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({FloralThemeMode mode = FloralThemeMode.poppyBlush}) {
    Color primary;
    Color secondary;
    Color background;
    Color surface;
    Color text;

    switch (mode) {
      case FloralThemeMode.lavenderMeadow:
        primary = const Color(0xFFC7B5E8);
        secondary = FloralPalette.rosePetal;
        background = const Color(0xFFFAF7FD);
        surface = Colors.white;
        text = FloralPalette.warmCharcoal;
      case FloralThemeMode.sageGarden:
        primary = FloralPalette.sageGreen;
        secondary = FloralPalette.deepForestGreen;
        background = const Color(0xFFF7FAF7);
        surface = Colors.white;
        text = FloralPalette.warmCharcoal;
      case FloralThemeMode.midnightGarden:
        primary = const Color(0xFFE88FA6);
        secondary = const Color(0xFFC7B5E8);
        background = const Color(0xFF1E1A22); // Deep botanical plum
        surface = const Color(0xFF2B2531);
        text = const Color(0xFFF7EDF0);
      case FloralThemeMode.poppyBlush:
        primary = FloralPalette.rosePetal;
        secondary = FloralPalette.sageGreen;
        background = FloralPalette.petalWhite;
        surface = FloralPalette.softIvory;
        text = FloralPalette.warmCharcoal;
    }

    final isDark = mode == FloralThemeMode.midnightGarden;

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.nunitoTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: text,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: text,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: text,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? const Color(0xFFD6CAD0) : FloralPalette.mutedCharcoal,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        error: FloralPalette.poppyRed,
        onError: Colors.white,
        surface: surface,
        onSurface: text,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0x22FFFFFF) : const Color(0x33F8C8D4),
            width: 1.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x44F8C8D4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : const Color(0x44F8C8D4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}
