import 'package:flutter/material.dart';

/// Central color palette definitions for "Bookmark".
///
/// Designed with a soft, romantic botanical journal aesthetic:
/// creamy paper textures, delicate line-art doodles, and gentle pops of poppy red.
class FloralPalette {
  FloralPalette._();

  // Signature Core Colors
  static const Color blushPink = Color(0xFFF8C8D4);
  static const Color rosePetal = Color(0xFFE88FA6);
  static const Color poppyRed = Color(0xFFE2483D);
  static const Color poppyRedDark = Color(0xFFC0392B);
  static const Color petalWhite = Color(0xFFFFF9F7); // Warm cream paper background
  static const Color softIvory = Color(0xFFFFFFFF); // Card surfaces
  static const Color sageGreen = Color(0xFFA9C5A0);
  static const Color deepForestGreen = Color(0xFF5E7F62);
  static const Color lavenderMist = Color(0xFFD9CCF0);
  static const Color buttercupYellow = Color(0xFFF7DC8B);
  static const Color warmCharcoal = Color(0xFF4A3F44); // Body text
  static const Color mutedCharcoal = Color(0xFF7A6F74); // Subtitle / secondary text

  // Soft pink-tinted shadow (never harsh gray)
  static const Color softShadowTint = Color(0x28E88FA6);
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
