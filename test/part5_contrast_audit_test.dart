import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/core/theme/palette.dart';

double _linearize(double c) {
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Part 5: Comprehensive WCAG 2.1 Contrast Audit', () {
    test('Light Theme: All audited text tokens have >= 4.5:1 contrast against backgrounds', () {
      FloralPalette.currentMode = FloralThemeMode.poppyBlush;

      final bgIvory = FloralPalette.softIvory; // #FFFBF5

      // Warm charcoal (primary text)
      final crWarmIvory = _contrastRatio(FloralPalette.warmCharcoal, bgIvory);
      expect(crWarmIvory, greaterThanOrEqualTo(4.5), reason: 'warmCharcoal on softIvory must be >= 4.5:1');

      // Muted charcoal (secondary/hint text)
      final crMutedIvory = _contrastRatio(FloralPalette.mutedCharcoal, bgIvory);
      expect(crMutedIvory, greaterThanOrEqualTo(4.5), reason: 'mutedCharcoal on softIvory must be >= 4.5:1');

      // Cocoa (handwriting text)
      final crCocoaIvory = _contrastRatio(FloralPalette.cocoa, bgIvory);
      expect(crCocoaIvory, greaterThanOrEqualTo(4.5), reason: 'cocoa on softIvory must be >= 4.5:1');

      // Deep rose (accent/button label)
      final crDeepRoseIvory = _contrastRatio(FloralPalette.deepRose, bgIvory);
      expect(crDeepRoseIvory, greaterThanOrEqualTo(4.5), reason: 'deepRose on softIvory must be >= 4.5:1');

      // Buttercup gold
      final crButtercupIvory = _contrastRatio(FloralPalette.buttercupGold, bgIvory);
      expect(crButtercupIvory, greaterThanOrEqualTo(4.5), reason: 'buttercupGold on softIvory must be >= 4.5:1');

      // Page count pill text
      final crPageCount = _contrastRatio(FloralPalette.pageCountText, FloralPalette.kraftPaper);
      expect(crPageCount, greaterThanOrEqualTo(4.5), reason: 'pageCountText on kraftPaper must be >= 4.5:1');

      // Action button text
      final crAction = _contrastRatio(FloralPalette.actionButtonText, FloralPalette.actionButtonFill);
      expect(crAction, greaterThanOrEqualTo(4.5), reason: 'actionButtonText on actionButtonFill must be >= 4.5:1');

      // Undo snackbar action text (#A6482A on #FAF6F0)
      final crUndo = _contrastRatio(const Color(0xFFA6482A), const Color(0xFFFAF6F0));
      expect(crUndo, greaterThanOrEqualTo(4.5), reason: 'Undo snackbar action text must be >= 4.5:1');
    });

    test('Dark Theme: All audited text tokens have >= 4.5:1 contrast against dark backgrounds', () {
      FloralPalette.currentMode = FloralThemeMode.midnightGarden;

      final bgIvoryDark = FloralPalette.softIvory; // #2B211A

      // Warm charcoal (primary light text in dark mode)
      final crWarmDark = _contrastRatio(FloralPalette.warmCharcoal, bgIvoryDark);
      expect(crWarmDark, greaterThanOrEqualTo(4.5), reason: 'warmCharcoal on dark softIvory must be >= 4.5:1');

      // Muted charcoal (secondary light text in dark mode)
      final crMutedDark = _contrastRatio(FloralPalette.mutedCharcoal, bgIvoryDark);
      expect(crMutedDark, greaterThanOrEqualTo(4.5), reason: 'mutedCharcoal on dark softIvory must be >= 4.5:1');

      // Cocoa (handwriting text in dark mode)
      final crCocoaDark = _contrastRatio(FloralPalette.cocoa, bgIvoryDark);
      expect(crCocoaDark, greaterThanOrEqualTo(4.5), reason: 'cocoa on dark softIvory must be >= 4.5:1');

      // Deep rose (accent/button in dark mode)
      final crDeepRoseDark = _contrastRatio(FloralPalette.deepRose, bgIvoryDark);
      expect(crDeepRoseDark, greaterThanOrEqualTo(4.5), reason: 'deepRose on dark softIvory must be >= 4.5:1');

      // Poppy red dark (delete button in dark mode)
      final crPoppyDark = _contrastRatio(FloralPalette.poppyRedDark, bgIvoryDark);
      expect(crPoppyDark, greaterThanOrEqualTo(4.5), reason: 'poppyRedDark on dark softIvory must be >= 4.5:1');

      // Buttercup gold in dark mode
      final crButtercupDark = _contrastRatio(FloralPalette.buttercupGold, bgIvoryDark);
      expect(crButtercupDark, greaterThanOrEqualTo(4.5), reason: 'buttercupGold on dark softIvory must be >= 4.5:1');

      // Page count pill text in dark mode
      final crPageCount = _contrastRatio(FloralPalette.pageCountText, FloralPalette.kraftPaper);
      expect(crPageCount, greaterThanOrEqualTo(4.5), reason: 'pageCountText on dark kraftPaper must be >= 4.5:1');

      // Action button text in dark mode
      final crAction = _contrastRatio(FloralPalette.actionButtonText, FloralPalette.actionButtonFill);
      expect(crAction, greaterThanOrEqualTo(4.5), reason: 'actionButtonText on dark actionButtonFill must be >= 4.5:1');

      // Reset
      FloralPalette.currentMode = FloralThemeMode.midnightGarden;
    });
  });
}
