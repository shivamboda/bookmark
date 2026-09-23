import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../models/book.dart';

/// Renders a book cover with realistic book styling.
///
/// If no image is available, displays a beautiful botanical cloth/leather-cover
/// placeholder rotating between Blush, Sage, Latte, and Cocoa with an embossed
/// fully-opaque poppy motif and readable Fraunces typography.
class BookCoverThumbnail extends ConsumerWidget {
  final Book book;
  final double width;
  final double height;
  final double borderRadius;
  final bool enableHero;

  const BookCoverThumbnail({
    super.key,
    required this.book,
    this.width = 68,
    this.height = 100,
    this.borderRadius = 10,
    this.enableHero = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);

    final safeWidth = width.isFinite && width > 0 ? width : 72.0;
    final safeHeight = height.isFinite && height > 0 ? height : 108.0;

    Widget coverWidget = Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A4A3F44),
            blurRadius: 10,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: FutureBuilder(
          future: storage.getCoverImage(book.id),
          builder: (context, snapshot) {
            final bytes = book.coverBytes ?? snapshot.data;
            if (bytes != null && bytes.isNotEmpty) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: width.isFinite ? width : null,
                height: height.isFinite ? height : null,
              );
            }

            if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
              return Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                width: width.isFinite ? width : null,
                height: height.isFinite ? height : null,
                errorBuilder: (context, error, stackTrace) => _buildBotanicalPlaceholder(safeWidth, safeHeight),
              );
            }

            return _buildBotanicalPlaceholder(safeWidth, safeHeight);
          },
        ),
      ),
    );

    if (enableHero) {
      return Hero(
        tag: 'book-cover-${book.id}',
        child: coverWidget,
      );
    }

    return coverWidget;
  }

  Widget _buildBotanicalPlaceholder(double safeWidth, double safeHeight) {
    // Deterministic rotation among 4 botanical palettes:
    // 0: Blush cloth, 1: Sage linen, 2: Latte parchment, 3: Cocoa leather
    final variant = book.title.hashCode.abs() % 4;

    Color bgColor;
    Color borderColor;
    Color ruleColor;
    Color textColor;
    Color poppyColor;

    switch (variant) {
      case 0: // Blush cloth
        bgColor = const Color(0xFFFCE6EC);
        borderColor = FloralPalette.rosePetal.withValues(alpha: 0.35);
        ruleColor = FloralPalette.rosePetal.withValues(alpha: 0.55);
        textColor = FloralPalette.warmCharcoal;
        poppyColor = FloralPalette.poppyRed; // 100% opaque vibrant bloom
      case 1: // Sage linen
        bgColor = const Color(0xFFE4EDE1);
        borderColor = FloralPalette.deepForestGreen.withValues(alpha: 0.35);
        ruleColor = FloralPalette.deepForestGreen.withValues(alpha: 0.50);
        textColor = FloralPalette.warmCharcoal;
        poppyColor = FloralPalette.poppyRed; // 100% opaque, no green bleed
      case 2: // Latte parchment
        bgColor = const Color(0xFFEFE4D6);
        borderColor = FloralPalette.latte;
        ruleColor = FloralPalette.cocoa.withValues(alpha: 0.50);
        textColor = FloralPalette.espresso;
        poppyColor = FloralPalette.poppyRed; // 100% opaque
      case 3: // Cocoa leather
      default:
        bgColor = FloralPalette.cocoa; // #7A5240
        borderColor = FloralPalette.espresso;
        ruleColor = FloralPalette.kraftPaper.withValues(alpha: 0.70); // Lighter rule lines on cocoa
        textColor = FloralPalette.petalWhite; // Cream text for pristine readability (6.8:1 contrast)
        poppyColor = FloralPalette.poppyRed; // Fully opaque vibrant poppy, identical on all 4 covers
    }

    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top rule: Left-aligned and shortened to stop well before top-right status pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              height: 1.5,
              width: (safeWidth * 0.32).clamp(16.0, 42.0),
              color: ruleColor,
            ),
          ),

          // Fully opaque poppy motif in center (petals never translucent)
          PoppyDoodle(
            size: (safeWidth * 0.36).clamp(24.0, 52.0),
            showStem: false,
            petalColor: poppyColor,
          ),

          // Title (wraps naturally within cover bounds without mid-word ellipsis truncation)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: Text(
                  book.title,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: safeWidth < 70 ? 8.5 : 10.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),

          // Simulated embossed bottom line
          Container(
            height: 1.5,
            width: safeWidth * 0.6,
            color: ruleColor,
          ),
        ],
      ),
    );
  }
}
