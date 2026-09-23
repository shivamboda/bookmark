import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/bookmark_ribbon_doodle.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../doodles/vine_doodle.dart';
import '../../../models/book.dart';
import 'add_edit_book_screen.dart';
import '../widgets/book_cover_thumbnail.dart';

/// Step 4b: Handcrafted Botanical Book Detail Screen.
///
/// Features:
/// - Hero transition on book cover matching library list & grid
/// - Vine borders (Cocoa stem, Sage leaves) and floral dividers
/// - Half-star rating display in Buttercup Gold with interactive tap adjustment
/// - Reading status badge & quick-change selector (Latte & Espresso for Paused)
/// - Reading timeline: Added, Started, Finished dates
/// - Favorite quotes rendered as Kraft Paper cards with Cocoa text & ribbon corner
/// - Reflections and notes journal card with Latte hairlines
/// - Full SafeArea compliance & minimum 44x44 tap targets
class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Not yet recorded';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _openEditScreen(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditBookScreen(bookToEdit: book),
      ),
    );
  }

  Future<void> _updateRating(Book book, double newRating) async {
    final updated = book.copyWith(rating: newRating);
    await ref.read(booksProvider.notifier).updateBook(updated);
  }

  Future<void> _updateStatus(Book book, ReadingStatus newStatus) async {
    await ref.read(booksProvider.notifier).updateStatus(book.id, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final allBooks = booksAsync.value ?? [];
    final book = allBooks.where((b) => b.id == widget.bookId).firstOrNull;

    if (book == null) {
      return Scaffold(
        backgroundColor: FloralPalette.petalWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: FloralPalette.warmCharcoal),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DaisyDoodle(size: 64, showStem: false),
                const SizedBox(height: 16),
                Text(
                  'Book not found in your journal',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                ),
                const SizedBox(height: 8),
                Text(
                  'This story may have been relocated or archived.',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                // Top Custom Botanical Navigation Bar (Tap targets >= 44x44)
                _buildTopNavBar(context, book),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover & Primary Info Header
                        _buildCoverAndHeader(context, book),

                        const SizedBox(height: 20),

                        // Section 1: Half-Star Rating Display & Interactive Selector
                        _buildRatingSection(context, book),

                        const SizedBox(height: 20),

                        // Floral Vine Divider (Cocoa stem, Sage leaves)
                        const VineBorderDoodle(
                          height: 20,
                          stemColor: FloralPalette.cocoa,
                          leafColor: FloralPalette.sageGreen,
                        ),

                        const SizedBox(height: 18),

                        // Section 2: Reading Status Quick Selector
                        _buildStatusSection(context, book),

                        const SizedBox(height: 20),

                        // Section 3: Reading Journey & Dates Timeline Card
                        _buildDatesSection(context, book),

                        const SizedBox(height: 22),

                        // Section 4: Favorite Quotes (Kraft Paper note cards with Cocoa text)
                        _buildFavoriteQuotesSection(context, book),

                        const SizedBox(height: 22),

                        // Section 5: Reflections & Marginalia Notes Card
                        _buildNotesSection(context, book),

                        if (book.description.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          // Section 6: Synopsis / Description
                          _buildSynopsisSection(context, book),
                        ],

                        const SizedBox(height: 36),

                        // Closing Botanical Flourish
                        Center(
                          child: Column(
                            children: [
                              const DaisyDoodle(size: 40, showStem: false),
                              const SizedBox(height: 6),
                              Text(
                                'from the pages of your reading journal ~',
                                style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top app bar with guaranteed 44x44 tap targets
  Widget _buildTopNavBar(BuildContext context, Book book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('detail_back_button'),
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
                    boxShadow: const [FloralPalette.cardShadow],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: FloralPalette.cocoa,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),

          // Central Breadcrumb
          Expanded(
            child: Column(
              children: [
                Text(
                  'BOOKMARK • JOURNAL ENTRY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.bodySmall(
                    color: FloralPalette.deepForestGreen,
                  ).copyWith(
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Book Details',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.headingSmall(
                    color: FloralPalette.warmCharcoal,
                  ).copyWith(fontSize: 16),
                ),
              ],
            ),
          ),

          // Edit Button (Placeholder for Step 4c)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('detail_edit_button'),
              onTap: () => _openEditScreen(context, book),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
                    boxShadow: const [FloralPalette.cardShadow],
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: FloralPalette.deepRose,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cover hero and typography header (handles very long titles gracefully)
  Widget _buildCoverAndHeader(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Book Cover (120 x 180)
              Hero(
                tag: 'book-cover-${book.id}',
                child: BookCoverThumbnail(
                  book: book,
                  width: 120,
                  height: 180,
                  borderRadius: 12,
                ),
              ),

              const SizedBox(width: 16),

              // Title, Author, Page Count, Genres
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title in Fraunces (soft wrap, handles very long titles)
                    Text(
                      book.title,
                      style: JournalTypography.headingMedium(
                        color: FloralPalette.warmCharcoal,
                      ).copyWith(fontSize: 20, height: 1.25),
                    ),

                    const SizedBox(height: 4),

                    const HandDrawnUnderline(
                      width: 80,
                      color: FloralPalette.deepRose,
                    ),

                    const SizedBox(height: 8),

                    // Author in Lora
                    Text(
                      book.authorDisplay,
                      style: JournalTypography.subheading(
                        color: FloralPalette.mutedCharcoal,
                      ).copyWith(fontSize: 14),
                    ),

                    const SizedBox(height: 10),

                    // Page Count badge if available
                    if (book.pageCount != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: FloralPalette.kraftPaper,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FloralPalette.latte, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories_outlined, size: 13, color: FloralPalette.cocoa),
                            const SizedBox(width: 4),
                            Text(
                              '${book.pageCount} pages',
                              style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Genres wrapped
                    if (book.genres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: book.genres.map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: FloralPalette.blushPink.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF2DED9), width: 0.8),
                            ),
                            child: Text(
                              g,
                              style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Interactive Half-Star Rating Section
  Widget _buildRatingSection(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rating',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
              ),
              Text(
                book.isRated ? '${book.rating!.toStringAsFixed(1)} / 5.0' : 'Unrated',
                style: JournalTypography.bodySmall(
                  color: book.isRated ? FloralPalette.buttercupGold : FloralPalette.unratedText,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 5-Star Row with Half-Star display and 44x44 tap targets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final starIndex = index + 1.0;
              IconData icon;
              Color iconColor;

              if (book.ratingOrZero >= starIndex) {
                icon = Icons.star_rounded;
                iconColor = FloralPalette.buttercupGold;
              } else if (book.ratingOrZero >= starIndex - 0.5) {
                icon = Icons.star_half_rounded;
                iconColor = FloralPalette.buttercupGold;
              } else {
                icon = Icons.star_outline_rounded;
                iconColor = FloralPalette.latte;
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('rating_star_${index + 1}'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Tap toggles: if current rating is full, drop to half; else set full
                    double newRating = starIndex;
                    if (book.ratingOrZero == starIndex) {
                      newRating = starIndex - 0.5;
                    } else if (book.ratingOrZero == starIndex - 0.5) {
                      newRating = starIndex - 1.0;
                    }
                    _updateRating(book, newRating);
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 32,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Status Selector with Palette Badges (Latte fill + Espresso text for Paused)
  Widget _buildStatusSection(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Status',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
              ),
              Flexible(
                child: Text(
                  'tap to update',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4 Status Pill Options (All tap targets >= 44x44)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReadingStatus.values.map((status) {
              final isSelected = book.status == status;

              Color bg;
              Color text;
              Color border;

              switch (status) {
                case ReadingStatus.wantToRead:
                  bg = isSelected ? FloralPalette.lavenderMist : Colors.white;
                  text = isSelected ? FloralPalette.lavenderDark : FloralPalette.warmCharcoal;
                  border = isSelected ? FloralPalette.lavenderDark : const Color(0xFFE2D6DC);
                case ReadingStatus.reading:
                  bg = isSelected ? const Color(0xFFD6E6D2) : Colors.white;
                  text = isSelected ? FloralPalette.sageGreenDark : FloralPalette.warmCharcoal;
                  border = isSelected ? FloralPalette.sageGreenDark : const Color(0xFFE2D6DC);
                case ReadingStatus.finished:
                  bg = isSelected ? FloralPalette.blushPink : Colors.white;
                  text = isSelected ? FloralPalette.deepRose : FloralPalette.warmCharcoal;
                  border = isSelected ? FloralPalette.deepRose : const Color(0xFFE2D6DC);
                case ReadingStatus.paused:
                  bg = isSelected ? FloralPalette.latte : Colors.white;
                  text = isSelected ? FloralPalette.espresso : FloralPalette.warmCharcoal; // 6.42:1 contrast
                  border = isSelected ? FloralPalette.cocoa : const Color(0xFFE2D6DC);
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('status_chip_${status.name}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _updateStatus(book, status),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: isSelected ? 1.4 : 1.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: border.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        status.label,
                        style: JournalTypography.bodySmall(color: text).copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Reading Journey & Dates Timeline Card
  Widget _buildDatesSection(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: FloralPalette.cocoa),
              const SizedBox(width: 8),
              Text(
                'Reading Timeline',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildTimelineRow(
            icon: Icons.bookmark_add_outlined,
            iconColor: FloralPalette.deepRose,
            label: 'Added to Library',
            value: _formatDate(book.dateAdded),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFF4E9E6), height: 1),
          ),

          _buildTimelineRow(
            icon: Icons.menu_book_rounded,
            iconColor: FloralPalette.deepForestGreen,
            label: 'Started Reading',
            value: book.startDate != null ? _formatDate(book.startDate) : 'Not yet started',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Color(0xFFF4E9E6), height: 1),
          ),

          _buildTimelineRow(
            icon: Icons.task_alt_rounded,
            iconColor: FloralPalette.cocoa,
            label: 'Completed',
            value: book.finishDate != null
                ? _formatDate(book.finishDate)
                : (book.status == ReadingStatus.finished ? 'Recently completed' : 'In progress ~'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// Favorite Quotes Section: Rendered as Kraft Paper note cards with Cocoa text and brown ribbon corner
  Widget _buildFavoriteQuotesSection(BuildContext context, Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Quotes',
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
            ),
            Flexible(
              child: Text(
                '• cherished lines',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (book.quotes.isEmpty) ...[
          // Empty quotes state with Kraft paper styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FloralPalette.kraftPaper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: FloralPalette.latte, width: 1.0),
              boxShadow: const [FloralPalette.cardShadow],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  top: -20,
                  right: 12,
                  child: BookmarkRibbonDoodle(width: 14, height: 26),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No favorite quotes saved yet.',
                      style: JournalTypography.body(color: FloralPalette.cocoa).copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'save the lines that made you pause and dream ~',
                      style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          ...book.quotes.map((q) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: FloralPalette.kraftPaper, // Kraft paper note card
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: FloralPalette.latte, width: 1.0),
                boxShadow: const [FloralPalette.cardShadow],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Small brown ribbon corner resting on top-right
                  const Positioned(
                    top: -18,
                    right: 10,
                    child: BookmarkRibbonDoodle(width: 14, height: 26),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quote in Lora italic with Cocoa text (passes 5.5:1 contrast on Kraft)
                      Text(
                        '“${q.quote}”',
                        style: JournalTypography.bodyLarge(color: FloralPalette.cocoa).copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                      ),

                      if (q.pageNumber != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— page ${q.pageNumber}',
                            style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Reflections & Marginalia Notes Card (Latte hairline border)
  Widget _buildNotesSection(BuildContext context, Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reflections & Notes',
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
            ),
            Flexible(
              child: Text(
                '• reader thoughts',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
            boxShadow: const [FloralPalette.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (book.notes.isNotEmpty) ...[
                Text(
                  book.notes,
                  style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                Text(
                  'No notes recorded for this story yet.',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your thoughts, marginalia, and memories will appear here ~',
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Synopsis Card
  Widget _buildSynopsisSection(BuildContext context, Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
            boxShadow: const [FloralPalette.cardShadow],
          ),
          child: Text(
            book.description,
            style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}