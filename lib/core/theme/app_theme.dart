import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Named typography tokens for "Bookmark".
///
/// Evokes an intimate botanical journal or pressed-flower diary:
/// - Headings: Fraunces (warm, characterful optical serif)
/// - Body: Lora (cozy, highly readable book-weight serif)
/// - Handwritten Accents: Caveat (intimate cursive script for margin notes, taglines, quotes)
class JournalTypography {
  JournalTypography._();

  /// Grand hero title (e.g. journal cover title)
  static TextStyle headingHero({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.6,
        height: 1.15,
      );

  /// Primary screen heading
  static TextStyle headingLarge({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// Section or card heading
  static TextStyle headingMedium({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
      );

  /// Small section or shelf header
  static TextStyle headingSmall({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  /// Elegant editorial subheading
  static TextStyle subheading({Color color = FloralPalette.mutedCharcoal}) =>
      GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color,
        height: 1.4,
      );

  /// Default body reading text
  static TextStyle body({Color color = FloralPalette.warmCharcoal}) => bodyMedium(color: color);

  /// Main body reading text (comfortable line height for reviews & synopses)
  static TextStyle bodyLarge({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.6,
      );

  /// Secondary body text (book metadata, tags, details)
  static TextStyle bodyMedium({Color color = FloralPalette.warmCharcoal}) =>
      GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.5,
      );

  /// Small caption / timestamps
  static TextStyle bodySmall({Color color = FloralPalette.mutedCharcoal}) =>
      GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
        height: 1.4,
      );

  /// Expressive handwritten script (taglines, chapter headers)
  static TextStyle handwritingLarge({Color color = FloralPalette.poppyRed}) =>
      GoogleFonts.caveat(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.1,
      );

  /// Standard handwritten note (quotes, intimate annotations)
  static TextStyle handwriting({Color color = FloralPalette.deepForestGreen}) =>
      GoogleFonts.caveat(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
      );

  /// Delicate margin note or footnote tucked beside cards
  static TextStyle marginNote({Color color = FloralPalette.mutedCharcoal}) =>
      GoogleFonts.caveat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color,
        height: 1.1,
      );
}

/// Central theme builder for "Bookmark".
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

    final isDark = mode == FloralThemeMode.midnightGarden || mode == FloralThemeMode.poppyBlush;

    final baseTextTheme = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    final textTheme = GoogleFonts.loraTextTheme(baseTextTheme).copyWith(
      displayLarge: JournalTypography.headingHero(color: text),
      displayMedium: JournalTypography.headingLarge(color: text),
      displaySmall: JournalTypography.headingMedium(color: text),
      headlineMedium: JournalTypography.headingSmall(color: text),
      titleLarge: JournalTypography.headingSmall(color: text),
      titleMedium: JournalTypography.subheading(color: text),
      bodyLarge: JournalTypography.bodyLarge(color: text),
      bodyMedium: JournalTypography.bodyMedium(
        color: isDark ? const Color(0xFFD6CAD0) : FloralPalette.mutedCharcoal,
      ),
      bodySmall: JournalTypography.bodySmall(
        color: isDark ? const Color(0xFFAFA2A8) : FloralPalette.mutedCharcoal,
      ),
      labelLarge: GoogleFonts.lora(
        fontSize: 15,
        fontWeight: FontWeight.w600,
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
            color: isDark ? const Color(0x22FFFFFF) : FloralPalette.cardBorder,
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
        titleTextStyle: JournalTypography.headingMedium(color: text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FloralPalette.deepRose,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
            color: isDark ? const Color(0x33FFFFFF) : FloralPalette.cardBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : FloralPalette.cardBorder,
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

