import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/floral_rating_bar.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../models/book.dart';
import 'book_cover_thumbnail.dart';

/// Grid view card displaying a book cover with botanical styling,
/// palette status pill, rating, and Fraunces title.
class BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const BookGridItem({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {


    return Container(
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Material(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          hoverColor: FloralPalette.blushPink.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover with status badge overlay
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;

                      return Stack(
                        children: [
                          Center(
                            child: BookCoverThumbnail(
                              book: book,
                              width: w,
                              height: h,
                              borderRadius: 8,
                              enableHero: true,
                            ),
                          ),
                          if (isSelectionMode)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? FloralPalette.deepRose : FloralPalette.softIvory.withValues(alpha: 0.85),
                                  border: Border.all(
                                    color: isSelected ? FloralPalette.deepRose : FloralPalette.mutedCharcoal.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: FloralPalette.softIvory,
                                      )
                                    : null,
                              ),
                            ),
                          // Floating Status Pill at top-right
                          Positioned(
                            top: 6,
                            right: 6,
                            child: StatusPill(
                              status: book.status,
                              fontSize: 12.0,
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Title in Fraunces (handling long titles)
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.headingSmall(
                    color: FloralPalette.warmCharcoal,
                  ).copyWith(fontSize: 14, height: 1.2),
                ),

                const SizedBox(height: 2),

                // Author in Lora
                Text(
                  book.authorDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.subheading(
                    color: FloralPalette.mutedCharcoal,
                  ).copyWith(fontSize: 12),
                ),

                const SizedBox(height: 6),

                // Rating (if rated)
                Row(
                  children: [
                    if (book.isRated) ...[
                      const BotanicalBlossomIcon(
                        size: 15,
                        fillFraction: 1.0,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        book.rating!.toStringAsFixed(1),
                        style: JournalTypography.bodySmall(
                          color: FloralPalette.warmCharcoal,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Unrated',
                        style: JournalTypography.bodySmall(
                          color: FloralPalette.unratedText, // #756A70
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
