import 'package:flutter/material.dart';

/// Central color palette definitions for "Bookmark".
///
/// Cozy Autumn Evening Dark Journal Theme:
/// deep espresso background (#1E1611), warm cocoa card surfaces (#2B211A),
/// glowing apricot & pumpkin accents (#F2C9A0, #D98A4E), rich rust buttons (#A6482A),
/// poppy ember signature (#E0533C), olive sage leaves (#C2BD6E),
/// moss stems (#8E9E60), dusty mauve wishlist (#E3C6D0),
/// golden amber highlights (#EBB84A), warm ivory body text (#F5EBE1),
/// and toasted oat secondary text (#C4B2A5).
class FloralPalette {
  FloralPalette._();

  // Signature Core Colors (Cozy Autumn Evening Theme)
  static const Color blushPink = Color(0xFFF2C9A0); // Primary soft accent: Apricot (#F2C9A0)
  static const Color rosePetal = Color(0xFFD98A4E); // Decorative accent: Pumpkin (#D98A4E)
  static const Color deepRose = Color(0xFFA6482A); // Button color with white text: Rust (#A6482A)
  static const Color poppyRed = Color(0xFFE0533C); // Signature accent: Poppy Ember (#E0533C)
  static const Color poppyRedDark = Color(0xFFB33622); // Deep Poppy Ember
  static const Color petalWhite = Color(0xFF1E1611); // Main background: Deep Espresso (#1E1611)
  static const Color softIvory = Color(0xFF2B211A); // Cards & surfaces: Warm Cocoa (#2B211A)
  static const Color sageGreen = Color(0xFFC2BD6E); // Leaves and "Reading" status: Olive Sage (#C2BD6E)
  static const Color sageGreenDark = Color(0xFF8E9E60); // Stems and green text: Moss (#8E9E60)
  static const Color deepForestGreen = Color(0xFF8E9E60); // Stems and green text: Moss (#8E9E60)
  static const Color lavenderMist = Color(0xFFE3C6D0); // "Want to Read" status: Dusty Mauve (#E3C6D0)
  static const Color lavenderDark = Color(0xFFD4A3B4); // Mauve text/accent
  static const Color buttercupYellow = Color(0xFFEBB84A); // Highlights and poppy centers: Golden Amber (#EBB84A)
  static const Color buttercupDark = Color(0xFFC68A00);
  static const Color buttercupGold = Color(0xFFEBB84A); // Highlights and poppy centers: Golden Amber (#EBB84A)
  static const Color unratedText = Color(0xFF9E8C80); // Soft brown unrated caption
  static const Color warmCharcoal = Color(0xFFF5EBE1); // Body text: Warm Ivory / Light Cream (#F5EBE1)
  static const Color mutedCharcoal = Color(0xFFC4B2A5); // Subtitle / secondary text: Toasted Oat (#C4B2A5)

  // Warm Brown Accent Palette (Adapted for Dark Harmony)
  static const Color espresso = Color(0xFFF5EBE1); // Readable text role
  static const Color cocoa = Color(0xFFD98A4E); // Pumpkin/warm cocoa accent
  static const Color caramel = Color(0xFFB9825A); // Caramel #B9825A
  static const Color latte = Color(0xFF4A382C); // Dark hairline dividers & spines
  static const Color kraftPaper = Color(0xFF382B22); // Panel background on dark

  // Autumn card hairline borders & panel backgrounds
  static const Color cardBorder = Color(0xFF3D2E24);
  static const Color bannerBackground = Color(0xFF261C16);

  // Soft warm autumn amber shadow
  static const Color softShadowTint = Color(0x35000000);
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
