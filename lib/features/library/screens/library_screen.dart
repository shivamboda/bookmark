import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/leaf_sprig_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../doodles/tulip_doodle.dart';
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
/// - List and Grid view toggle with generous 140px bottom padding
/// - Palette-based status pills (Lavender, Sage, Blush, Buttercup)
/// - Full approved botanical poppy header flower positioned fully inside the screen
/// - Handcrafted empty state with open book + poppy illustration
/// - Botanical bottom navigation where all 4 tabs switch to active views
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
            child: IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildLibraryTab(context, booksAsync),
                _buildWishlistTab(context, booksAsync),
                _buildStatsTab(context, booksAsync),
                _buildSettingsTab(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloralBottomNav(
        currentIndex: _currentNavIndex,
        onTabSelected: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
      floatingActionButton: (_currentNavIndex == 0 || _currentNavIndex == 1)
          ? FloatingActionButton(
              key: const ValueKey('add_book_fab'),
              onPressed: () => _showAddBookPlaceholder(context),
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: Colors.white,
              elevation: 3,
              tooltip: 'Add Book',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }

  // ==========================================
  // TAB 0: LIBRARY SCREEN
  // ==========================================
  Widget _buildLibraryTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Stack(
      children: [
        // Full approved botanical poppy positioned fully inside the screen (no clipping, no overlap)
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: PoppyDoodle(
              size: 72,
              showStem: false,
              petalColor: FloralPalette.rosePetal, // Full approved bloom with inner petals, pod & stamens
            ),
          ),
        ),

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
                  final books = _filterBooks(allBooks);

                  if (books.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                      child: LibraryEmptyState(
                        onAddBook: () => _showAddBookPlaceholder(context),
                      ),
                    );
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      key: const ValueKey('library_grid_view'),
                      // 140px bottom padding so floating action button never covers last card
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
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
                    // 140px bottom padding so floating action button never covers last card
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
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
    );
  }

  // ==========================================
  // TAB 1: WISHLIST SCREEN
  // ==========================================
  Widget _buildWishlistTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Stack(
      children: [
        // Tulip motif resting in top-right
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: TulipDoodle(
              size: 68,
              showStem: false,
              petalColor: FloralPalette.rosePetal,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • WISHLIST',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
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
                            'Wishlist',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: FloralPalette.warmCharcoal,
                            ),
                          ),
                          SizedBox(height: 2),
                          HandDrawnUnderline(
                            width: 115,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• future dreams to read',
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
            ),

            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: FloralPalette.deepRose),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (allBooks) {
                  final wishlistBooks = allBooks.where((b) => b.status == ReadingStatus.wantToRead).toList();

                  if (wishlistBooks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const TulipDoodle(size: 72, showStem: false, petalColor: FloralPalette.rosePetal),
                            const SizedBox(height: 16),
                            Text(
                              'Your wishlist is waiting for future stories ~',
                              textAlign: TextAlign.center,
                              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'add books you dream of reading next',
                              style: JournalTypography.handwriting(color: FloralPalette.deepForestGreen),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
                    itemCount: wishlistBooks.length,
                    itemBuilder: (context, index) {
                      return BookListCard(
                        book: wishlistBooks[index],
                        onTap: () => _onBookSelected(context, wishlistBooks[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: STATS SCREEN
  // ==========================================
  Widget _buildStatsTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    final yearlyGoal = ref.watch(yearlyGoalProvider) ?? 20;

    return Stack(
      children: [
        // Daisy motif in top-right
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: DaisyDoodle(
              size: 68,
              showStem: false,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • READING STATS',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
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
                            'Stats',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: FloralPalette.warmCharcoal,
                            ),
                          ),
                          SizedBox(height: 2),
                          HandDrawnUnderline(
                            width: 80,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• pages and memories',
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
            ),

            Expanded(
              child: booksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: FloralPalette.deepRose)),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (allBooks) {
                  final finishedCount = allBooks.where((b) => b.status == ReadingStatus.finished).length;
                  final readingCount = allBooks.where((b) => b.status == ReadingStatus.reading).length;
                  final wishlistCount = allBooks.where((b) => b.status == ReadingStatus.wantToRead).length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                    child: Column(
                      children: [
                        // Yearly Goal Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFF2DED9)),
                            boxShadow: const [FloralPalette.cardShadow],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2026 Reading Goal',
                                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$finishedCount of $yearlyGoal books finished',
                                style: JournalTypography.handwriting(color: FloralPalette.deepRose),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: yearlyGoal > 0 ? (finishedCount / yearlyGoal).clamp(0.0, 1.0) : 0,
                                  backgroundColor: FloralPalette.blushPink.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation(FloralPalette.deepRose),
                                  minHeight: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatTile('Reading', '$readingCount', FloralPalette.sageGreenDark),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatTile('Finished', '$finishedCount', FloralPalette.deepRose),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatTile('Wishlist', '$wishlistCount', FloralPalette.lavenderDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2DED9)),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: JournalTypography.headingLarge(color: color).copyWith(fontSize: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: SETTINGS SCREEN
  // ==========================================
  Widget _buildSettingsTab(BuildContext context) {
    final yearlyGoal = ref.watch(yearlyGoalProvider) ?? 20;

    return Stack(
      children: [
        // Leaf sprig motif in top-right
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: LeafSprigDoodle(
              size: 58,
              color: FloralPalette.deepForestGreen,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • SETTINGS',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
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
                            'Settings',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: FloralPalette.warmCharcoal,
                            ),
                          ),
                          SizedBox(height: 2),
                          HandDrawnUnderline(
                            width: 115,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• personal preferences',
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
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                child: Column(
                  children: [
                    // Reading Goal Setting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF2DED9)),
                        boxShadow: const [FloralPalette.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yearly Reading Goal', style: JournalTypography.headingSmall()),
                          const SizedBox(height: 4),
                          Text('Set your target number of books for this year', style: JournalTypography.bodySmall()),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$yearlyGoal books',
                                style: JournalTypography.headingMedium(color: FloralPalette.deepRose),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: yearlyGoal > 1
                                        ? () => ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal - 1)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline_rounded),
                                    color: FloralPalette.deepRose,
                                  ),
                                  IconButton(
                                    onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal + 1),
                                    icon: const Icon(Icons.add_circle_outline_rounded),
                                    color: FloralPalette.deepRose,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme Palette Information
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF2DED9)),
                        boxShadow: const [FloralPalette.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme & Palette', style: JournalTypography.headingSmall()),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const PoppyDoodle(size: 24, showStem: false, petalColor: FloralPalette.rosePetal),
                              const SizedBox(width: 8),
                              Text('Poppy Blush (Signature)', style: JournalTypography.subheading()),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Crafted with love for romantic book lovers', style: JournalTypography.bodySmall()),
                        ],
                      ),
                    ),

                    // Developer Doodle Showcase (visible strictly in kDebugMode)
                    if (kDebugMode && widget.onOpenDoodleGallery != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: widget.onOpenDoodleGallery,
                        icon: const Icon(Icons.palette_outlined, size: 20),
                        label: const Text('🌸 Open Botanical Doodle Sketchbook'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FloralPalette.deepRose,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Header with Fraunces title, hand-drawn underline, and romantic journal label
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                                : Colors.white,
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
                    color: Colors.white,
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
}
