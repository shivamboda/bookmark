import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../models/book.dart';
import 'book_cover_thumbnail.dart';

/// Rich journal-style card displaying a book in List View.
class BookListCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const BookListCard({
    super.key,
    required this.book,
    this.onTap,
  });

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
        badgeBg = FloralPalette.buttercupYellow.withValues(alpha: 0.40);
        badgeText = FloralPalette.buttercupDark;
        badgeBorder = FloralPalette.buttercupDark.withValues(alpha: 0.35);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover
                BookCoverThumbnail(
                  book: book,
                  width: 72,
                  height: 106,
                  borderRadius: 8,
                ),

                const SizedBox(width: 14),

                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Pill & Rating
                      Row(
                        children: [
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
                          const Spacer(),
                          if (book.rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: Color(0xFFE5A922),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              book.rating.toStringAsFixed(1),
                              style: JournalTypography.bodySmall(
                                color: FloralPalette.warmCharcoal,
                              ).copyWith(fontWeight: FontWeight.w700),
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
                          '“${book.quotes.first.quote}”',
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
