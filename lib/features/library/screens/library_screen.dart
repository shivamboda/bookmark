import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../models/book.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/book_list_card.dart';
import '../widgets/floral_bottom_nav.dart';
import '../widgets/library_empty_state.dart';

/// Filter option for books displayed in the Library screen.
enum LibraryFilter {
  all('All Books'),
  reading('Reading'),
  wantToRead('Want to Read'),
  finished('Finished');

  final String label;
  const LibraryFilter(this.label);
}

/// Step 4a: Handcrafted Botanical Library Screen.
///
/// Features:
/// - List and Grid view toggle
/// - Palette-based status pills (Lavender, Sage, Blush, Buttercup)
/// - Botanical floral header with blush poppy peeking from the top-right corner
/// - Handcrafted empty state with open book + poppy illustration
/// - Botanical bottom navigation with blush poppy icon
/// - Complete SafeArea handling for iPhone 16
/// - 44px+ minimum tap targets
class LibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenDoodleGallery;

  const LibraryScreen({
    super.key,
    this.onOpenDoodleGallery,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isGridView = false;
  LibraryFilter _activeFilter = LibraryFilter.all;
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Stack(
              children: [
                // Corner Botanical Motif: Blush Poppy peeking from top-right corner
                const Positioned(
                  top: -16,
                  right: -14,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.90,
                      child: PoppyDoodle(
                        size: 92,
                        showStem: false,
                        petalColor: FloralPalette.rosePetal, // Blush poppy variant
                      ),
                    ),
                  ),
                ),

                // Main Scrollable Content
                Column(
                  children: [
                    // Top App Header
                    _buildHeader(context),

                    // Filter Chips & View Mode Toggle Bar
                    _buildControlsBar(),

                    // Book Collection / Empty State
                    Expanded(
                      child: booksAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: FloralPalette.deepRose,
                            strokeWidth: 2.5,
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Unable to load your library: $error',
                              style: JournalTypography.bodySmall(color: Colors.red.shade800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        data: (allBooks) {
                          // Apply status filter
                          final books = _filterBooks(allBooks);

                          if (books.isEmpty) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: LibraryEmptyState(
                                onAddBook: () => _showAddBookPlaceholder(context),
                              ),
                            );
                          }

                          if (_isGridView) {
                            return GridView.builder(
                              key: const ValueKey('library_grid_view'),
                              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.60,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return BookGridItem(
                                  book: book,
                                  onTap: () => _onBookSelected(context, book),
                                );
                              },
                            );
                          }

                          return ListView.builder(
                            key: const ValueKey('library_list_view'),
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return BookListCard(
                                book: book,
                                onTap: () => _onBookSelected(context, book),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloralBottomNav(
        currentIndex: _currentNavIndex,
        onTabSelected: (index) {
          setState(() => _currentNavIndex = index);
          if (index != 0) {
            _showTabPlaceholder(context, index);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_book_fab'),
        onPressed: () => _showAddBookPlaceholder(context),
        backgroundColor: FloralPalette.deepRose,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Add Book',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  /// Header with Fraunces title, hand-drawn underline, and romantic journal label
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BOOKMARK • READING JOURNAL',
                style: JournalTypography.bodySmall(
                  color: FloralPalette.deepForestGreen,
                ).copyWith(
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (kDebugMode && widget.onOpenDoodleGallery != null)
                Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: InkWell(
                    onTap: widget.onOpenDoodleGallery,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FloralPalette.blushPink.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FloralPalette.deepRose.withValues(alpha: 0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '🌸 Doodles',
                          style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Library',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: FloralPalette.warmCharcoal,
                    ),
                  ),
                  SizedBox(height: 2),
                  HandDrawnUnderline(
                    width: 105,
                    color: FloralPalette.deepRose,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '• quiet garden of stories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(
                    color: FloralPalette.mutedCharcoal,
                  ).copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Controls bar containing status filter chips and list/grid toggle
  Widget _buildControlsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(
        children: [
          // Filter Chips (Horizontally Scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LibraryFilter.values.map((filter) {
                  final isSelected = _activeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _activeFilter = filter),
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? FloralPalette.deepRose
                                : FloralPalette.softIvory,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? FloralPalette.deepRose
                                  : const Color(0xFFF0DCD7),
                              width: 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: FloralPalette.deepRose.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            filter.label,
                            style: JournalTypography.bodySmall(
                              color: isSelected ? Colors.white : FloralPalette.warmCharcoal,
                            ).copyWith(
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
            ),
          ),

          const SizedBox(width: 8),

          // List / Grid Mode Toggle Button (44px+ tap target)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('view_mode_toggle_btn'),
              onTap: () => setState(() => _isGridView = !_isGridView),
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: FloralPalette.softIvory,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF0DCD7), width: 1.0),
                  ),
                  child: Icon(
                    _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
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

  List<Book> _filterBooks(List<Book> books) {
    switch (_activeFilter) {
      case LibraryFilter.all:
        return books;
      case LibraryFilter.reading:
        return books.where((b) => b.status == ReadingStatus.reading).toList();
      case LibraryFilter.wantToRead:
        return books.where((b) => b.status == ReadingStatus.wantToRead).toList();
      case LibraryFilter.finished:
        return books.where((b) => b.status == ReadingStatus.finished).toList();
    }
  }

  void _onBookSelected(BuildContext context, Book book) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected "${book.title}" • Detail screen opens in Step 4b'),
        duration: const Duration(seconds: 2),
        backgroundColor: FloralPalette.warmCharcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddBookPlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add / Edit Book form arrives in Step 4c ✨'),
        duration: const Duration(seconds: 2),
        backgroundColor: FloralPalette.deepRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTabPlaceholder(BuildContext context, int index) {
    final tabNames = ['Library', 'Wishlist', 'Stats', 'Settings'];
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tabNames[index]} tab • Coming soon in next phases'),
        duration: const Duration(seconds: 2),
        backgroundColor: FloralPalette.warmCharcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
