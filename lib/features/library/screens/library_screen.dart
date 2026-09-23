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
import '../../../doodles/bookmark_ribbon_doodle.dart';
import 'book_detail_screen.dart';
import 'book_search_screen.dart';

/// Status filter options for books displayed in the Library screen.
enum LibraryStatusFilter {
  all('All'),
  reading('Reading'),
  finished('Finished'),
  paused('Paused/DNF');

  final String label;
  const LibraryStatusFilter(this.label);
}

/// Sorting options for the user's reading journal shelf.
enum LibrarySortOption {
  dateFinished('Date Finished'),
  dateAdded('Date Added'),
  rating('Rating'),
  title('Title'),
  author('Author');

  final String label;
  const LibrarySortOption(this.label);
}

/// Step 4a: Handcrafted Botanical Library Screen.
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
  LibraryStatusFilter _activeStatusFilter = LibraryStatusFilter.all;
  String? _selectedGenre;
  LibrarySortOption _sortOption = LibrarySortOption.dateAdded;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final savedGrid = await storage.getSetting('library_is_grid_view');
      final savedSort = await storage.getSetting('library_sort_option');

      if (mounted) {
        setState(() {
          if (savedGrid is bool) {
            _isGridView = savedGrid;
          }
          if (savedSort is String) {
            _sortOption = LibrarySortOption.values.firstWhere(
              (o) => o.name == savedSort,
              orElse: () => LibrarySortOption.dateAdded,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading library settings: $e');
    }
  }

  Future<void> _toggleViewMode() async {
    final newMode = !_isGridView;
    setState(() => _isGridView = newMode);
    try {
      await ref.read(storageServiceProvider).setSetting('library_is_grid_view', newMode);
    } catch (e) {
      debugPrint('Failed to save grid view setting: $e');
    }
  }

  Future<void> _setSortOption(LibrarySortOption option) async {
    setState(() => _sortOption = option);
    try {
      await ref.read(storageServiceProvider).setSetting('library_sort_option', option.name);
    } catch (e) {
      debugPrint('Failed to save sort option setting: $e');
    }
  }

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
              onPressed: () => _openAddBookScreen(context),
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
        // Brown bookmark ribbon accent peeking gracefully from top edge
        const Positioned(
          top: 0,
          right: 78,
          child: IgnorePointer(
            child: BookmarkRibbonDoodle(
              width: 14,
              height: 32,
            ),
          ),
        ),

        // Full approved botanical poppy positioned fully inside the screen
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: PoppyDoodle(
              size: 72,
              showStem: false,
              petalColor: FloralPalette.rosePetal,
            ),
          ),
        ),

        Column(
          children: [
            // Top App Header
            _buildHeader(context),

            // Filter Chips, Search & View Mode Toggle Bar
            _buildControlsBar(booksAsync.value ?? []),

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
                  if (allBooks.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                      child: LibraryEmptyState(
                        onAddBook: () => _openAddBookScreen(context, defaultStatus: ReadingStatus.reading),
                      ),
                    );
                  }

                  final books = _filterAndSortBooks(allBooks);

                  if (books.isEmpty) {
                    return _buildNoMatchesState();
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      key: const ValueKey('library_grid_view'),
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
                        children: [
                          Text(
                            'Wishlist',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
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
                            color: FloralPalette.cocoa,
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
                  final wishlistBooks = allBooks
                      .where((b) => b.status == ReadingStatus.wantToRead)
                      .toList()
                    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

                  if (wishlistBooks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: LibraryEmptyState(
                          title: "Books you'd love to read someday live here ~",
                          subtitle: "add stories you dream of reading next",
                          buttonLabel: "Find a Book",
                          onAddBook: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BookSearchScreen(),
                            ),
                          ),
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
                        isWishlist: true,
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
    final yearlyGoal = ref.watch(yearlyGoalProvider);
    final currentYear = DateTime.now().year;

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
                        children: [
                          Text(
                            'Stats',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
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
                        // Yearly Goal Card (Dynamic Year & Friendly Unset State)
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
                                '$currentYear Reading Goal',
                                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                              ),
                              const SizedBox(height: 6),
                              if (yearlyGoal == null) ...[
                                Text(
                                  'Set a goal for the year ~',
                                  style: JournalTypography.handwriting(color: FloralPalette.deepRose),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Track how many books you wish to finish in $currentYear. Head over to Settings to pick a goal whenever you are ready.',
                                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _currentNavIndex = 3),
                                  icon: const Icon(Icons.flag_outlined, size: 18),
                                  label: const Text('Set Goal in Settings'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FloralPalette.deepRose,
                                    side: const BorderSide(color: FloralPalette.deepRose),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    minimumSize: const Size(44, 44),
                                  ),
                                ),
                              ] else ...[
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
    final yearlyGoal = ref.watch(yearlyGoalProvider);
    final currentYear = DateTime.now().year;

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
                        children: [
                          Text(
                            'Settings',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
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
                            color: FloralPalette.cocoa,
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
                          Text('Set your target number of books for $currentYear', style: JournalTypography.bodySmall()),
                          const SizedBox(height: 14),

                          if (yearlyGoal == null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'No goal set',
                                    style: JournalTypography.subheading(color: FloralPalette.unratedText),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(12),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FloralPalette.deepRose,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(44, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('Set a goal for the year'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$yearlyGoal books',
                                  style: JournalTypography.headingMedium(color: FloralPalette.deepRose),
                                ),
                                Row(
                                  children: [
                                    // Minus button with guaranteed >= 44x44 hit area
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                        onPressed: () {
                                          if (yearlyGoal <= 1) {
                                            ref.read(yearlyGoalProvider.notifier).setGoal(null);
                                          } else {
                                            ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal - 1);
                                          }
                                        },
                                        tooltip: yearlyGoal <= 1 ? 'Clear goal' : 'Decrease goal',
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 26),
                                        color: FloralPalette.deepRose,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Plus button with guaranteed >= 44x44 hit area
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                        onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal + 1),
                                        tooltip: 'Increase goal',
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
                                        color: FloralPalette.deepRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(null),
                                style: TextButton.styleFrom(
                                  foregroundColor: FloralPalette.mutedCharcoal,
                                  minimumSize: const Size(44, 44),
                                ),
                                child: const Text('Clear Goal', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
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

                    // Developer Doodle Showcase (strictly kDebugMode, no emoji)
                    if (kDebugMode && widget.onOpenDoodleGallery != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: widget.onOpenDoodleGallery,
                        icon: const Icon(Icons.palette_outlined, size: 20),
                        label: const Text('Open Botanical Doodle Sketchbook'),
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
                children: [
                  Text(
                    'Library',
                    style: JournalTypography.headingLarge(
                      color: FloralPalette.warmCharcoal,
                    ).copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 2),
                  const HandDrawnUnderline(
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
                    color: FloralPalette.cocoa,
                  ).copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Friendly empty state when search or filters return 0 results
  Widget _buildNoMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TulipDoodle(size: 64, showStem: false, petalColor: FloralPalette.rosePetal),
            const SizedBox(height: 16),
            Text(
              'Nothing matches that yet ~',
              textAlign: TextAlign.center,
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'try adjusting your search, filters, or shelves ~',
              textAlign: TextAlign.center,
              style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const ValueKey('clear_filters_btn'),
              onPressed: () {
                setState(() {
                  _activeStatusFilter = LibraryStatusFilter.all;
                  _selectedGenre = null;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Controls bar containing search field, status filter chips, genre dropdown, sort dropdown, and list/grid toggle
  Widget _buildControlsBar(List<Book> allBooks) {
    final availableGenres = allBooks.expand((b) => b.genres).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Box for personal library (title & author)
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
              boxShadow: const [FloralPalette.cardShadow],
            ),
            child: TextField(
              key: const ValueKey('library_search_input'),
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search shelf by title or author...',
                hintStyle: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: FloralPalette.cocoa),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: FloralPalette.mutedCharcoal),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Status Filter Chips (All, Reading, Finished, Paused/DNF)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: LibraryStatusFilter.values.map((filter) {
                final isSelected = _activeStatusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: ValueKey('status_chip_${filter.name}'),
                    onTap: () => setState(() => _activeStatusFilter = filter),
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? FloralPalette.deepRose : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? FloralPalette.deepRose : const Color(0xFFF0DCD7),
                            width: 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: FloralPalette.deepRose.withValues(alpha: 0.22),
                                    blurRadius: 6,
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
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Secondary Controls: Genre Filter, Sort Options, Grid/List Mode
          Row(
            children: [
              // Genre Filter Button / Dropdown
              PopupMenuButton<String?>(
                key: const ValueKey('genre_filter_button'),
                initialValue: _selectedGenre,
                onSelected: (genre) => setState(() => _selectedGenre = genre),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String?>(
                      value: null,
                      child: Text(
                        'All Genres',
                        style: JournalTypography.bodySmall(
                          color: _selectedGenre == null ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                        ).copyWith(fontWeight: _selectedGenre == null ? FontWeight.w700 : FontWeight.w500),
                      ),
                    ),
                    ...availableGenres.map(
                      (g) => PopupMenuItem<String?>(
                        value: g,
                        key: ValueKey('genre_item_$g'),
                        child: Text(
                          g,
                          style: JournalTypography.bodySmall(
                            color: _selectedGenre == g ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                          ).copyWith(fontWeight: _selectedGenre == g ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                    ),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedGenre != null
                        ? FloralPalette.blushPink.withValues(alpha: 0.3)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGenre != null ? FloralPalette.deepRose : const Color(0xFFF0DCD7),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 15,
                        color: _selectedGenre != null ? FloralPalette.deepRose : FloralPalette.cocoa,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedGenre ?? 'All Genres',
                        style: JournalTypography.bodySmall(
                          color: _selectedGenre != null ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Sort Option Button / Dropdown
              PopupMenuButton<LibrarySortOption>(
                key: const ValueKey('sort_option_button'),
                initialValue: _sortOption,
                onSelected: (opt) => _setSortOption(opt),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) {
                  return LibrarySortOption.values.map(
                    (opt) => PopupMenuItem<LibrarySortOption>(
                      value: opt,
                      key: ValueKey('sort_item_${opt.name}'),
                      child: Row(
                        children: [
                          if (_sortOption == opt) ...[
                            const Icon(Icons.check_rounded, size: 14, color: FloralPalette.deepRose),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            opt.label,
                            style: JournalTypography.bodySmall(
                              color: _sortOption == opt ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                            ).copyWith(fontWeight: _sortOption == opt ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0DCD7), width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_vert_rounded, size: 15, color: FloralPalette.cocoa),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption.label,
                        style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // List / Grid Mode Toggle Button (44px+ tap target)
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey('view_mode_toggle_btn'),
                  onTap: _toggleViewMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0DCD7), width: 1.0),
                    ),
                    child: Icon(
                      _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                      color: FloralPalette.deepRose,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Book> _filterAndSortBooks(List<Book> allBooks) {
    // 1. Status Filter
    var filtered = allBooks.where((b) {
      switch (_activeStatusFilter) {
        case LibraryStatusFilter.all:
          return true;
        case LibraryStatusFilter.reading:
          return b.status == ReadingStatus.reading;
        case LibraryStatusFilter.finished:
          return b.status == ReadingStatus.finished;
        case LibraryStatusFilter.paused:
          return b.status == ReadingStatus.paused;
      }
    }).toList();

    // 2. Genre Filter
    if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
      filtered = filtered.where((b) => b.genres.contains(_selectedGenre)).toList();
    }

    // 3. Search Query (title and author)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        final titleMatch = b.title.toLowerCase().contains(query);
        final authorMatch = b.authors.any((a) => a.toLowerCase().contains(query));
        return titleMatch || authorMatch;
      }).toList();
    }

    // 4. Sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case LibrarySortOption.dateFinished:
          if (a.finishDate == null && b.finishDate == null) return b.dateAdded.compareTo(a.dateAdded);
          if (a.finishDate == null) return 1;
          if (b.finishDate == null) return -1;
          return b.finishDate!.compareTo(a.finishDate!);
        case LibrarySortOption.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case LibrarySortOption.rating:
          final rA = a.rating ?? 0.0;
          final rB = b.rating ?? 0.0;
          final cmp = rB.compareTo(rA);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.author:
          final authA = (a.authors.firstOrNull ?? '').toLowerCase();
          final authB = (b.authors.firstOrNull ?? '').toLowerCase();
          final cmp = authA.compareTo(authB);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  void _onBookSelected(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(bookId: book.id),
      ),
    );
  }

  void _openAddBookScreen(BuildContext context, {ReadingStatus? defaultStatus}) {
    final status = defaultStatus ??
        (_currentNavIndex == 1
            ? ReadingStatus.wantToRead
            : ReadingStatus.reading);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSearchScreen(defaultStatus: status),
      ),
    );
  }
}
