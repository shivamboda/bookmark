import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../models/book.dart';
import 'book_cover_thumbnail.dart';

/// Rich journal-style card displaying a book in List View.
class BookListCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final bool isWishlist;

  const BookListCard({
    super.key,
    required this.book,
    this.onTap,
    this.isWishlist = false,
  });

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Added ${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    // Palette-based status colors
    Color badgeBg;
    Color badgeText;
    Color badgeBorder;

    switch (book.status) {
      case ReadingStatus.wantToRead:
        badgeBg = FloralPalette.lavenderMist.withValues(alpha: 0.35);
        badgeText = FloralPalette.lavenderDark;
        badgeBorder = FloralPalette.lavenderDark.withValues(alpha: 0.35);
      case ReadingStatus.reading:
        badgeBg = FloralPalette.sageGreen.withValues(alpha: 0.35);
        badgeText = FloralPalette.sageGreenDark;
        badgeBorder = FloralPalette.sageGreenDark.withValues(alpha: 0.35);
      case ReadingStatus.finished:
        badgeBg = FloralPalette.blushPink.withValues(alpha: 0.45);
        badgeText = FloralPalette.deepRose;
        badgeBorder = FloralPalette.deepRose.withValues(alpha: 0.35);
      case ReadingStatus.paused:
        badgeBg = FloralPalette.latte;
        badgeText = FloralPalette.espresso; // 6.42:1 WCAG AA contrast on Latte
        badgeBorder = FloralPalette.cocoa.withValues(alpha: 0.45);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: FloralPalette.blushPink.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover with Hero transition
                BookCoverThumbnail(
                  book: book,
                  width: 72,
                  height: 106,
                  borderRadius: 8,
                  enableHero: !isWishlist,
                ),

                const SizedBox(width: 14),

                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Pill & Rating (or "Added <date>" on Wishlist)
                      Row(
                        children: [
                          if (isWishlist) ...[
                            Text(
                              _formatDate(book.dateAdded),
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.mutedCharcoal,
                              ).copyWith(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: badgeBorder, width: 0.8),
                              ),
                              child: Text(
                                book.status.label,
                                style: JournalTypography.bodySmall(color: badgeText).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (book.isRated) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: FloralPalette.buttercupGold, // Deeper buttercup gold for contrast on white
                            ),
                            const SizedBox(width: 3),
                            Text(
                              book.rating!.toStringAsFixed(1),
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.warmCharcoal,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ] else if (!isWishlist) ...[
                            Text(
                              'Unrated',
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.unratedText, // #756A70
                              ).copyWith(fontSize: 11),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Title in Fraunces (handling long titles with ellipsis)
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: JournalTypography.headingSmall(
                          color: FloralPalette.warmCharcoal,
                        ).copyWith(fontSize: 16, height: 1.25),
                      ),

                      const SizedBox(height: 3),

                      // Author in Lora
                      Text(
                        book.authorDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JournalTypography.subheading(
                          color: FloralPalette.mutedCharcoal,
                        ).copyWith(fontSize: 13),
                      ),

                      const SizedBox(height: 8),

                      // Genres
                      if (book.genres.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: book.genres.take(3).map((g) {
                              return Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: FloralPalette.blushPink.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  g,
                                  style: JournalTypography.bodySmall(
                                    color: FloralPalette.warmCharcoal,
                                  ).copyWith(fontSize: 11),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Saved Quote snippet if present
                      if (book.quotes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${book.quotes.first.quote}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JournalTypography.marginNote(
                            color: FloralPalette.deepRose,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
