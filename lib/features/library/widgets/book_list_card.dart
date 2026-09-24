import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/floral_rating_bar.dart';
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



  @override
  Widget build(BuildContext context) {


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Material(
        color: FloralPalette.softIvory,
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
                      // Status Pill & Rating (Hidden entirely on Wishlist: shows cover, title, author, genres; hides rating and dates)
                      if (!isWishlist) ...[
                        Row(
                          children: [
                            StatusPill(
                              status: book.status,
                              fontSize: 12.5,
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            ),
                            const Spacer(),
                            if (book.isRated) ...[
                              const BotanicalBlossomIcon(
                                size: 16,
                                fillFraction: 1.0,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                book.rating!.toStringAsFixed(1),
                                style: JournalTypography.bodySmall(
                                  color: FloralPalette.warmCharcoal,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ] else ...[
                              Text(
                                'Unrated',
                                style: JournalTypography.bodySmall(
                                  color: FloralPalette.unratedText,
                                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],

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
                      if (book.cleanGenres.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: book.cleanGenres.take(3).map((g) {
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
                          BookQuote.formatSnippet(book.quotes.first.quote),
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
