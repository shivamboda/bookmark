import '../../../core/widgets/status_pill.dart';
import '../../../services/synopsis_service.dart';
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
import '../../../core/widgets/floral_rating_bar.dart';
import '../../../core/widgets/floral_celebration_overlay.dart';

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
  bool _isSynopsisExpanded = false;
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

  /// Triggers full-screen floral petal celebration when a book is finished.
  void _onBookFinishedCelebrationHook(Book finishedBook) {
    debugPrint('Book finished celebration hook triggered for "${finishedBook.title}" (ID: ${finishedBook.id})');
    if (mounted) {
      showFloralCelebration(context, bookTitle: finishedBook.title);
    }
  }

  Future<void> _updateStatus(Book book, ReadingStatus newStatus) async {
    await ref.read(booksProvider.notifier).updateStatus(book.id, newStatus);
    if (newStatus == ReadingStatus.finished) {
      final updated = book.copyWith(
        status: ReadingStatus.finished,
        finishDate: book.finishDate ?? DateTime.now(),
      );
      _onBookFinishedCelebrationHook(updated);
    }
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
            icon: Icon(Icons.arrow_back_rounded, color: FloralPalette.warmCharcoal),
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

                        // Prominent Wishlist Action: "I have it / Start reading"
                        if (book.status == ReadingStatus.wantToRead) ...[
                          const SizedBox(height: 16),
                          _buildStartReadingPrompt(context, book),
                        ],

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

                        const SizedBox(height: 22),
                        // Section 6: Synopsis / Description
                        _buildSynopsisSection(context, book),

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
            color: FloralPalette.softIvory,
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
                    border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                    boxShadow: [FloralPalette.cardShadow],
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
            color: FloralPalette.softIvory,
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
                    border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                    boxShadow: [FloralPalette.cardShadow],
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
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
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
                    if (book.cleanGenres.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: book.cleanGenres.map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: FloralPalette.blushPink.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FloralPalette.cardBorder, width: 0.8),
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
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
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
          Center(
            child: FloralRatingBar(
              rating: book.rating,
              blossomSize: 34,
              spacing: 12,
              onRatingChanged: (newRating) {
                _updateRating(book, newRating ?? 0.0);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Book book) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
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
              final pillStyle = StatusPillStyle.of(status);

              final Color bg = isSelected ? pillStyle.fill : FloralPalette.softIvory;
              final Color text = isSelected ? pillStyle.text : FloralPalette.warmCharcoal;
              final Color border = isSelected ? pillStyle.border : FloralPalette.cardBorder;

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
                        border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            pillStyle.icon,
                            size: 15,
                            color: text,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status.label,
                            style: JournalTypography.bodySmall(color: text).copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
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
            value: book.formattedCompletionDate.isNotEmpty
                ? book.formattedCompletionDate
                : (book.status == ReadingStatus.finished ? 'Read long ago' : 'In progress ~'),
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
              boxShadow: [FloralPalette.cardShadow],
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
                boxShadow: [FloralPalette.cardShadow],
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
                        q.displayQuote,
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
            color: FloralPalette.softIvory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
            boxShadow: [FloralPalette.cardShadow],
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

  /// Prominent prompt card displayed when a book is in "Want to Read" status
  Widget _buildStartReadingPrompt(BuildContext context, Book book) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.deepRose.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [FloralPalette.cardShadow],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FloralPalette.blushPink.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: FloralPalette.deepRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to read this story?',
                      style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
                    ),
                    Text(
                      'move from wishlist into your journal ~',
                      style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('start_reading_button'),
              onPressed: () => _showStartReadingBottomSheet(context, book),
              icon: const Icon(Icons.bookmark_added_rounded, size: 18),
              label: const Text(
                'I have it / Start reading',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartReadingBottomSheet(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
        ),
        child: _StartReadingBottomSheet(
          book: book,
          onSave: (updated) async {
            await ref.read(booksProvider.notifier).updateBook(updated);
            if (updated.status == ReadingStatus.finished) {
              _onBookFinishedCelebrationHook(updated);
            }
          },
        ),
      ),
    );
  }

  /// Synopsis Card
  Widget _buildSynopsisSection(BuildContext context, Book book) {
    final hasDesc = book.description.trim().isNotEmpty;
    final isLong = book.description.length > 260;

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
            color: FloralPalette.softIvory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
            boxShadow: [FloralPalette.cardShadow],
          ),
          child: hasDesc
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isLong && !_isSynopsisExpanded)
                          ? SynopsisCleaner.truncatePreview(book.description, maxLength: 260)
                          : book.description,
                      style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(
                        height: 1.5,
                        fontSize: 13.5,
                      ),
                    ),
                    if (isLong) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        key: const ValueKey('synopsis_toggle_btn'),
                        onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isSynopsisExpanded ? 'Show less' : 'Read more',
                                style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _isSynopsisExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: FloralPalette.deepRose,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No synopsis yet ~',
                        style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const ValueKey('add_synopsis_btn'),
                        onPressed: () => _openEditScreen(context, book),
                        icon: const Icon(Icons.edit_note_rounded, size: 18, color: FloralPalette.deepRose),
                        label: const Text(
                          'Add your own',
                          style: TextStyle(
                            color: FloralPalette.deepRose,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _StartReadingBottomSheet extends StatefulWidget {
  final Book book;
  final Future<void> Function(Book updated) onSave;

  const _StartReadingBottomSheet({
    required this.book,
    required this.onSave,
  });

  @override
  State<_StartReadingBottomSheet> createState() => _StartReadingBottomSheetState();
}

class _StartReadingBottomSheetState extends State<_StartReadingBottomSheet> {
  // Mode: 0 = "Starting now", 1 = "Already finished"
  int _modeIndex = 0;

  late DateTime _startDate;
  DateTime? _alreadyFinishedStartDate;
  late DateTime _finishDate;
  double? _rating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _finishDate = DateTime.now();
    _rating = widget.book.rating;
  }

  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSaving = true);
    try {
      if (_modeIndex == 0) {
        // "Starting now"
        final updated = widget.book.copyWith(
          status: ReadingStatus.reading,
          startDate: _startDate,
        );
        await widget.onSave(updated);
      } else {
        // "Already finished"
        final updated = widget.book.copyWith(
          status: ReadingStatus.finished,
          startDate: _alreadyFinishedStartDate,
          finishDate: _finishDate,
          rating: _rating,
        );
        await widget.onSave(updated);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2A402E32),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FloralPalette.latte,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Text(
                'Update Reading Status',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Move "${widget.book.title}" to your shelf ~',
                style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
              ),

              const SizedBox(height: 18),

              // Segmented Choice: "Starting now" vs "Already finished"
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: FloralPalette.petalWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('tab_starting_now'),
                        onTap: () => setState(() => _modeIndex = 0),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _modeIndex == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _modeIndex == 0 ? [FloralPalette.cardShadow] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Starting now',
                            style: JournalTypography.bodySmall(
                              color: _modeIndex == 0 ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
                            ).copyWith(
                              fontWeight: _modeIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('tab_already_finished'),
                        onTap: () => setState(() => _modeIndex = 1),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _modeIndex == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _modeIndex == 1 ? [FloralPalette.cardShadow] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Already finished',
                            style: JournalTypography.bodySmall(
                              color: _modeIndex == 1 ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
                            ).copyWith(
                              fontWeight: _modeIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content based on choice
              if (_modeIndex == 0) ...[
                // "Starting now" Form
                Text(
                  'Reading begins today',
                  style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  key: const ValueKey('start_date_picker_btn'),
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _startDate,
                    onPicked: (d) => _startDate = d,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: FloralPalette.petalWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FloralPalette.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: FloralPalette.deepRose),
                            const SizedBox(width: 8),
                            Text(
                              'Start Date: ${_formatDateShort(_startDate)}',
                              style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontSize: 13.5),
                            ),
                          ],
                        ),
                        Text(
                          'Change',
                          style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const ValueKey('confirm_start_reading_btn'),
                    onPressed: _isSaving ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FloralPalette.deepRose,
                      foregroundColor: FloralPalette.softIvory,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Begin Reading', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ] else ...[
                // "Already finished" Form
                // Optional Start Date
                InkWell(
                  key: const ValueKey('already_finished_start_date_btn'),
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _alreadyFinishedStartDate ?? _finishDate,
                    onPicked: (d) => _alreadyFinishedStartDate = d,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: FloralPalette.petalWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FloralPalette.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bookmark_border_rounded, size: 16, color: FloralPalette.cocoa),
                            const SizedBox(width: 8),
                            Text(
                              _alreadyFinishedStartDate == null
                                  ? 'Start Date: (Optional)'
                                  : 'Start Date: ${_formatDateShort(_alreadyFinishedStartDate!)}',
                              style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          _alreadyFinishedStartDate == null ? 'Set' : 'Change',
                          style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Finish Date (defaults to today)
                InkWell(
                  key: const ValueKey('finish_date_picker_btn'),
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _finishDate,
                    onPicked: (d) => _finishDate = d,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: FloralPalette.petalWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FloralPalette.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 16, color: FloralPalette.sageGreenDark),
                            const SizedBox(width: 8),
                            Text(
                              'Finish Date: ${_formatDateShort(_finishDate)}',
                              style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          'Change',
                          style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Optional Rating
                Row(
                  children: [
                    Text(
                      'Rating (optional):',
                      style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(5, (index) {
                      final starVal = index + 1.0;
                      final isFilled = (_rating ?? 0.0) >= starVal;
                      return InkWell(
                        key: ValueKey('sheet_star_$starVal'),
                        onTap: () => setState(() => _rating = (_rating == starVal) ? null : starVal),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 24,
                            color: isFilled ? FloralPalette.buttercupGold : FloralPalette.latte,
                          ),
                        ),
                      );
                    }),
                    if (_rating != null) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => setState(() => _rating = null),
                        child: Text(
                          'Clear',
                          style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const ValueKey('confirm_already_finished_btn'),
                    onPressed: _isSaving ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FloralPalette.deepRose,
                      foregroundColor: FloralPalette.softIvory,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Mark Finished', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
