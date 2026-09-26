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
  static TextStyle headingHero({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: color ?? FloralPalette.warmCharcoal,
        letterSpacing: -0.6,
        height: 1.15,
      );

  /// Primary screen heading
  static TextStyle headingLarge({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? FloralPalette.warmCharcoal,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// Section or card heading
  static TextStyle headingMedium({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color ?? FloralPalette.warmCharcoal,
        height: 1.25,
      );

  /// Small section or shelf header
  static TextStyle headingSmall({Color? color}) =>
      GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? FloralPalette.warmCharcoal,
        height: 1.3,
      );

  /// Elegant editorial subheading
  static TextStyle subheading({Color? color}) =>
      GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color ?? FloralPalette.mutedCharcoal,
        height: 1.4,
      );

  /// Default body reading text
  static TextStyle body({Color? color}) => bodyMedium(color: color);

  /// Main body reading text (comfortable line height for reviews & synopses)
  static TextStyle bodyLarge({Color? color}) =>
      GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color ?? FloralPalette.warmCharcoal,
        height: 1.6,
      );

  /// Secondary body text (book metadata, tags, details)
  static TextStyle bodyMedium({Color? color}) =>
      GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color ?? FloralPalette.warmCharcoal,
        height: 1.5,
      );

  /// Small caption / timestamps
  static TextStyle bodySmall({Color? color}) =>
      GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? FloralPalette.mutedCharcoal,
        height: 1.4,
      );

  /// Expressive handwritten script (taglines, chapter headers)
  static TextStyle handwritingLarge({Color? color}) =>
      GoogleFonts.caveat(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: color ?? FloralPalette.poppyRed,
        height: 1.1,
      );

  /// Standard handwritten note (quotes, intimate annotations)
  static TextStyle handwriting({Color? color}) =>
      GoogleFonts.caveat(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: color ?? FloralPalette.deepForestGreen,
        height: 1.2,
      );

  /// Delicate margin note or footnote tucked beside cards
  static TextStyle marginNote({Color? color}) =>
      GoogleFonts.caveat(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color ?? FloralPalette.mutedCharcoal,
        height: 1.1,
      );
}

/// Central theme builder for "Bookmark".
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme({FloralThemeMode? mode}) {
    final effectiveMode = mode ?? FloralPalette.currentMode;
    final isDark = effectiveMode == FloralThemeMode.midnightGarden;

    Color primary;
    Color secondary;
    Color background;
    Color surface;
    Color text;

    switch (effectiveMode) {
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
        primary = FloralPalette.rosePetal;
        secondary = FloralPalette.sageGreen;
        background = FloralPalette.petalWhite;
        surface = FloralPalette.softIvory;
        text = FloralPalette.warmCharcoal;
      case FloralThemeMode.poppyBlush:
        primary = FloralPalette.rosePetal;
        secondary = FloralPalette.sageGreen;
        background = FloralPalette.petalWhite;
        surface = FloralPalette.softIvory;
        text = FloralPalette.warmCharcoal;
    }

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
        color: FloralPalette.mutedCharcoal,
      ),
      bodySmall: JournalTypography.bodySmall(
        color: FloralPalette.mutedCharcoal,
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
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : FloralPalette.cardBorder,
            width: 1.0,
          ),
        ),
        headerBackgroundColor: isDark ? FloralPalette.petalWhite : FloralPalette.bannerBackground,
        headerForegroundColor: text,
        headerHeadlineStyle: GoogleFonts.lora(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        headerHelpStyle: GoogleFonts.lora(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: FloralPalette.mutedCharcoal,
        ),
        weekdayStyle: GoogleFonts.lora(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FloralPalette.mutedCharcoal,
        ),
        dayStyle: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return FloralPalette.mutedCharcoal.withValues(alpha: 0.38);
          }
          return text;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FloralPalette.deepRose;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return FloralPalette.rosePetal;
        }),
        todayBorder: const BorderSide(color: FloralPalette.rosePetal, width: 1.5),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return text;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return FloralPalette.deepRose;
          }
          return null;
        }),
        dividerColor: isDark ? const Color(0x22FFFFFF) : FloralPalette.cardBorder,
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: FloralPalette.mutedCharcoal,
          textStyle: GoogleFonts.lora(fontWeight: FontWeight.w600),
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: FloralPalette.deepRose,
          textStyle: GoogleFonts.lora(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : FloralPalette.cardBorder,
            width: 1.0,
          ),
        ),
        titleTextStyle: JournalTypography.headingMedium(color: text),
        contentTextStyle: JournalTypography.bodyMedium(color: text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBackgroundColor: surface,
        modalBarrierColor: Colors.black54,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0x33FFFFFF) : FloralPalette.cardBorder,
            width: 1.0,
          ),
        ),
        dialBackgroundColor: isDark ? FloralPalette.petalWhite : FloralPalette.bannerBackground,
        dialHandColor: FloralPalette.deepRose,
        dialTextColor: text,
        hourMinuteColor: isDark ? FloralPalette.petalWhite : FloralPalette.bannerBackground,
        hourMinuteTextColor: text,
        dayPeriodColor: isDark ? FloralPalette.petalWhite : FloralPalette.bannerBackground,
        dayPeriodTextColor: text,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: FloralPalette.mutedCharcoal),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: FloralPalette.deepRose),
      ),
    );
  }
}
