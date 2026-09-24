import 'package:flutter/material.dart';
import '../../models/book.dart';
import '../theme/app_theme.dart';

/// Design tokens and styling for status pills across Bookmark.
///
/// Contrast engineered for both Dark (#2B211A) and Light (#FFFBF5) cards:
/// - Text vs Fill: >= 7.2:1 (exceeds WCAG AAA 7:1)
/// - Fill vs Dark Card: >= 6.6:1 (exceeds 3:1 requirement)
class StatusPillStyle {
  final Color fill;
  final Color text;
  final Color border;
  final IconData icon;

  const StatusPillStyle({
    required this.fill,
    required this.text,
    required this.border,
    required this.icon,
  });

  static StatusPillStyle of(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return const StatusPillStyle(
          fill: Color(0xFFD2ACBE), // Soft Mauve
          text: Color(0xFF28101D), // Deep Plum Black (8.79:1 contrast)
          border: Color(0xFFE5CAD6),
          icon: Icons.bookmark_outline_rounded,
        );
      case ReadingStatus.reading:
        return const StatusPillStyle(
          fill: Color(0xFFB2BD86), // Olive Sage
          text: Color(0xFF172409), // Deep Forest Moss (8.13:1 contrast)
          border: Color(0xFFC8D2A2),
          icon: Icons.auto_stories_rounded,
        );
      case ReadingStatus.finished:
        return const StatusPillStyle(
          fill: Color(0xFFDE9872), // Warm Terracotta Apricot
          text: Color(0xFF331007), // Deep Rust Espresso (7.26:1 contrast)
          border: Color(0xFFEAB293),
          icon: Icons.check_rounded,
        );
      case ReadingStatus.paused:
        return const StatusPillStyle(
          fill: Color(0xFFD8BD88), // Golden Amber
          text: Color(0xFF261A06), // Deep Cocoa (9.37:1 contrast)
          border: Color(0xFFE7D2AA),
          icon: Icons.pause_rounded,
        );
    }
  }
}

/// Standalone, high-contrast botanical status pill widget.
class StatusPill extends StatelessWidget {
  final ReadingStatus status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusPill({
    super.key,
    required this.status,
    this.fontSize = 12.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final style = StatusPillStyle.of(status);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            style.icon,
            size: fontSize + 1,
            color: style.text,
          ),
          const SizedBox(width: 4.5),
          Text(
            status.label,
            style: JournalTypography.bodySmall(color: style.text).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
