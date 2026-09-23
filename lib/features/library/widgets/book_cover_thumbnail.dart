import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../models/book.dart';

/// Renders a book cover with realistic book styling.
///
/// If no image is available, displays a beautiful botanical cloth-cover
/// placeholder with title and debossed floral motif, never a blank gray box.
class BookCoverThumbnail extends ConsumerWidget {
  final Book book;
  final double width;
  final double height;
  final double borderRadius;

  const BookCoverThumbnail({
    super.key,
    required this.book,
    this.width = 68,
    this.height = 100,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageServiceProvider);

    final safeWidth = width.isFinite && width > 0 ? width : 72.0;
    final safeHeight = height.isFinite && height > 0 ? height : 108.0;

    return Container(
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
            final bytes = snapshot.data;
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
  }

  Widget _buildBotanicalPlaceholder(double safeWidth, double safeHeight) {
    // Generate harmonious seed tint based on book title length
    final isSage = book.title.length % 2 == 0;
    final bgColor = isSage ? const Color(0xFFE4EDE1) : const Color(0xFFFCE6EC);
    final accentColor = isSage ? FloralPalette.deepForestGreen : FloralPalette.rosePetal;

    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top rule: Stops well before top-right corner to never run behind status pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              height: 1.5,
              width: (safeWidth * 0.32).clamp(16.0, 42.0),
              color: accentColor.withValues(alpha: 0.4),
            ),
          ),

          // Mini floral motif in center
          PoppyDoodle(
            size: (safeWidth * 0.36).clamp(24.0, 52.0),
            showStem: false,
            petalColor: accentColor.withValues(alpha: 0.7),
          ),

          // Title snippet
          Text(
            book.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: safeWidth < 70 ? 9 : 11,
              fontWeight: FontWeight.w700,
              color: FloralPalette.warmCharcoal,
              height: 1.1,
            ),
          ),

          // Simulated embossed bottom line
          Container(
            height: 1.5,
            width: safeWidth * 0.6,
            color: accentColor.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
