import 'package:flutter/material.dart';

/// Central color palette definitions for "Bookmark".
///
/// Autumn Botanical Journal Theme:
/// warm parchment papers (#FBF3E8), soft cream cards (#FFFBF5),
/// rich apricot & pumpkin accents (#F2C9A0, #D98A4E), rust buttons (#A6482A),
/// poppy ember signature (#C8402A), olive sage leaves (#B7B36A),
/// moss stems (#5F6B3A), dusty mauve wishlist (#E3C6D0),
/// golden amber highlights (#EBB84A), and deep espresso body text (#4A3428).
class FloralPalette {
  FloralPalette._();

  // Signature Core Colors (Autumn Theme)
  static const Color blushPink = Color(0xFFF2C9A0); // Primary soft accent: Apricot (#F2C9A0)
  static const Color rosePetal = Color(0xFFD98A4E); // Decorative accent: Pumpkin (#D98A4E)
  static const Color deepRose = Color(0xFFA6482A); // Button color with white text: Rust (#A6482A)
  static const Color poppyRed = Color(0xFFC8402A); // Signature accent: Poppy Ember (#C8402A)
  static const Color poppyRedDark = Color(0xFF9E2C1A); // Deep Ember shadow
  static const Color petalWhite = Color(0xFFFBF3E8); // Main background: Warm Parchment (#FBF3E8)
  static const Color softIvory = Color(0xFFFFFBF5); // Cards: Soft Cream (#FFFBF5)
  static const Color sageGreen = Color(0xFFB7B36A); // Leaves and "Reading" status: Olive Sage (#B7B36A)
  static const Color sageGreenDark = Color(0xFF5F6B3A); // Stems and green text: Moss (#5F6B3A)
  static const Color deepForestGreen = Color(0xFF5F6B3A); // Stems and green text: Moss (#5F6B3A)
  static const Color lavenderMist = Color(0xFFE3C6D0); // "Want to Read" status: Dusty Mauve (#E3C6D0)
  static const Color lavenderDark = Color(0xFF6B4E5A); // Mauve text/accent
  static const Color buttercupYellow = Color(0xFFEBB84A); // Highlights and poppy centers: Golden Amber (#EBB84A)
  static const Color buttercupDark = Color(0xFFB58014);
  static const Color buttercupGold = Color(0xFFEBB84A); // Highlights and poppy centers: Golden Amber (#EBB84A)
  static const Color unratedText = Color(0xFF8A6B5A); // Soft brown unrated caption
  static const Color warmCharcoal = Color(0xFF4A3428); // Body text: Espresso (#4A3428)
  static const Color mutedCharcoal = Color(0xFF7A685D); // Subtitle / secondary text: Warm Espresso tint

  // Warm Brown Accent Palette (Preserved)
  static const Color espresso = Color(0xFF4A3428); // Espresso #4A3428
  static const Color cocoa = Color(0xFF7A5240); // Cocoa #7A5240
  static const Color caramel = Color(0xFFB9825A); // Caramel #B9825A
  static const Color latte = Color(0xFFD8BBA0); // Latte #D8BBA0
  static const Color kraftPaper = Color(0xFFF3E7DA); // Kraft #F3E7DA

  // Autumn card hairline borders & panel backgrounds
  static const Color cardBorder = Color(0xFFEADBCE);
  static const Color bannerBackground = Color(0xFFF7ECE0);

  // Soft warm autumn shadow
  static const Color softShadowTint = Color(0x1EA6482A);
  static const BoxShadow cardShadow = BoxShadow(
    color: softShadowTint,
    blurRadius: 18,
    spreadRadius: 0,
    offset: Offset(0, 6),
  );
}

/// Available theme modes for the app
enum FloralThemeMode {
  poppyBlush,
  lavenderMeadow,
  sageGarden,
  midnightGarden,
}
