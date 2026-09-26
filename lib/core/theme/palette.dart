import 'package:flutter/material.dart';

/// Available theme modes for Bookmark:
/// - [poppyBlush]: Autumn Day (Warm Parchment #FBF3E8 & Soft Cream #FFFBF5)
/// - [midnightGarden]: Autumn Night (Deep Espresso #1E1611 & Warm Cocoa #2B211A)
enum FloralThemeMode {
  poppyBlush,
  midnightGarden,
  lavenderMeadow,
  sageGarden,
}

/// Central color palette definitions for "Bookmark".
///
/// Supports both Autumn Day (Light) and Autumn Night (Dark) themes seamlessly.
/// Core accent roles (Apricot, Pumpkin, Rust, Poppy Ember, Olive Sage, Golden Amber)
/// remain consistent and harmonious across both modes.
class FloralPalette {
  FloralPalette._();

  static FloralThemeMode currentMode = FloralThemeMode.midnightGarden;
  static bool get isDark => currentMode == FloralThemeMode.midnightGarden;

  // Dynamic Backgrounds & Surfaces (Adapts automatically between Day and Night)
  static Color get petalWhite => isDark ? const Color(0xFF1E1611) : const Color(0xFFFBF3E8);
  static Color get softIvory => isDark ? const Color(0xFF2B211A) : const Color(0xFFFFFBF5);
  static Color get warmCharcoal => isDark ? const Color(0xFFF5EBE1) : const Color(0xFF4A3428);
  static Color get mutedCharcoal => isDark ? const Color(0xFFC4B2A5) : const Color(0xFF6E5A4E);
  static Color get cardBorder => isDark ? const Color(0xFF3D2E24) : const Color(0xFFEADBCE);
  static Color get bannerBackground => isDark ? const Color(0xFF261C16) : const Color(0xFFF7ECE0);
  static Color get latte => isDark ? const Color(0xFF4A382C) : const Color(0xFFD8BBA0);
  static Color get kraftPaper => isDark ? const Color(0xFF382B22) : const Color(0xFFF3E7DA);
  static Color get sageGreenDark => isDark ? const Color(0xFF8E9E60) : const Color(0xFF5F6B3A);
  static Color get deepForestGreen => isDark ? const Color(0xFF8E9E60) : const Color(0xFF5F6B3A);
  static Color get unratedText => isDark ? const Color(0xFFC9B8AB) : const Color(0xFF7A5C4D);

  // Signature Core Colors (Shared Autumn Accents)
  static const Color blushPink = Color(0xFFF2C9A0); // Primary soft accent: Apricot (#F2C9A0)
  static const Color rosePetal = Color(0xFFD98A4E); // Decorative accent: Pumpkin (#D98A4E)
  static const Color poppyRed = Color(0xFFC8402A); // Signature accent: Poppy Ember (#C8402A)
  static const Color sageGreen = Color(0xFFB7B36A); // Leaves and "Reading" status: Olive Sage (#B7B36A)
  static const Color lavenderMist = Color(0xFFE3C6D0); // "Want to Read" status: Dusty Mauve (#E3C6D0)
  static const Color buttercupYellow = Color(0xFFEBB84A); // Highlights and poppy centers: Golden Amber (#EBB84A)
  static const Color buttercupDark = Color(0xFFB58014);

  // Dynamic Text, Badge, and Action Tokens (Theme-aware for verified >= 4.5:1 contrast)
  static Color get deepRose => isDark ? const Color(0xFFE28A72) : const Color(0xFFA6482A);
  static Color get poppyRedDark => isDark ? const Color(0xFFFF8B7A) : const Color(0xFF9E2C1A);
  static Color get buttercupGold => isDark ? const Color(0xFFEBB84A) : const Color(0xFF8F6200);
  static Color get lavenderDark => isDark ? const Color(0xFFFFEBF3) : const Color(0xFF5A3142);
  static Color get espresso => isDark ? const Color(0xFFF5EBE1) : const Color(0xFF4A3428);
  static Color get cocoa => isDark ? const Color(0xFFD4BDB0) : const Color(0xFF7A5240);
  static Color get caramel => isDark ? const Color(0xFFE2B48E) : const Color(0xFFB9825A);

  // Shared Pill & Action Button Style tokens
  static Color get pageCountText => isDark ? const Color(0xFFF5EBE1) : const Color(0xFF4A3428);
  static Color get actionButtonFill => isDark ? const Color(0xFF422E39) : const Color(0xFFF3E5EC);
  static Color get actionButtonBorder => isDark ? const Color(0xFF8E5A73) : const Color(0xFFC48DA2);
  static Color get actionButtonText => isDark ? const Color(0xFFFFEBF3) : const Color(0xFF5A3142);

  // Soft warm autumn shadow
  static Color get softShadowTint => isDark ? const Color(0x35000000) : const Color(0x18A6482A);

  static BoxShadow get cardShadow => BoxShadow(
    color: softShadowTint,
    blurRadius: 18,
    spreadRadius: 0,
    offset: const Offset(0, 6),
  );
}
