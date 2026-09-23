import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/tulip_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../models/book.dart';
import 'add_edit_book_screen.dart';

/// Represents a candidate search result returned by book APIs.
class BookSearchResult {
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final int? pageCount;
  final String? description;
  final List<String> genres;

  const BookSearchResult({
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.pageCount,
    this.description,
    this.genres = const [],
  });
}

/// Book Search Screen: The entry point for finding and adding books to the journal.
///
/// Features:
/// - 500ms debounced search text input for titles or authors
/// - Distinct empty states: "before search" and "zero results found"
/// - Persistent "Add manually instead" option to bypass search at any time
/// - Loading state while search is in flight
/// - Fully styled in Poppy Blush / Fraunces-Lora-Caveat botanical design
class BookSearchScreen extends ConsumerStatefulWidget {
  final ReadingStatus defaultStatus;

  const BookSearchScreen({
    super.key,
    this.defaultStatus = ReadingStatus.reading,
  });

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isLoading = false;
  bool _hasSearched = false;
  List<BookSearchResult> _results = [];
  

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Debounces input changes by 500ms before triggering search
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasSearched = false;
        _results = [];
        
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _executeSearch(trimmed);
    });
  }

  /// Triggers book search (API integration wired in Part 2)
  Future<void> _executeSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      
    });

    // Simulated short delay in Part 1 to demonstrate loading & empty state
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasSearched = true;
      // In Part 1, results default to empty so the "no matches" state can be reviewed.
      // In Part 2, real Open Library & Google Books API data will be populated here.
      _results = [];
    });
  }

  /// Clear the search query and restore the initial empty state
  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _isLoading = false;
      _hasSearched = false;
      _results = [];
      
    });
    _searchFocusNode.requestFocus();
  }

  /// Navigates directly to the manual AddEditBookScreen
  Future<void> _openManualEntry([BookSearchResult? result]) async {
    Book? draft;
    if (result != null) {
      draft = Book(
        id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
        title: result.title,
        authors: result.authors,
        coverUrl: result.coverUrl,
        pageCount: result.pageCount,
        description: result.description ?? '',
        genres: result.genres,
        status: widget.defaultStatus,
        dateAdded: DateTime.now(),
      );
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditBookScreen(
          defaultStatus: widget.defaultStatus,
          prefilledDraft: draft,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                // Top Custom Botanical Navigation Bar
                _buildTopNavBar(context),

                // Search Input Field & Persistent Manual Entry link
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      _buildManualEntryBanner(),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Main Content: Initial Empty State, Loading, No-Results, or Results List
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top app bar with guaranteed >=44px tap targets
  Widget _buildTopNavBar(BuildContext context) {
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
              key: const ValueKey('search_back_button'),
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

          // Central Breadcrumb & Title
          Expanded(
            child: Column(
              children: [
                Text(
                  'BOOKMARK • SEARCH',
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
                  'Find a Story',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.headingSmall(
                    color: FloralPalette.warmCharcoal,
                  ).copyWith(fontSize: 16),
                ),
              ],
            ),
          ),

          // Shortcut: Add Manually button in navbar (>=44x44 hit target)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('search_nav_manual_btn'),
              onTap: () => _openManualEntry(),
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
                    Icons.edit_note_rounded,
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

  /// Rounded botanical search text field
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.2),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: TextField(
        key: const ValueKey('book_search_input'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onSubmitted: (val) {
          _debounceTimer?.cancel();
          _executeSearch(val.trim());
        },
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 16,
          color: FloralPalette.warmCharcoal,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search title, author, or keyword...',
          hintStyle: TextStyle(
            color: FloralPalette.mutedCharcoal.withValues(alpha: 0.65),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: FloralPalette.deepRose,
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('search_clear_button'),
                  icon: const Icon(Icons.clear_rounded, color: FloralPalette.mutedCharcoal, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Clearly visible persistent link/button to skip search entirely
  Widget _buildManualEntryBanner() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('add_manually_btn'),
        onTap: () => _openManualEntry(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.draw_outlined,
                size: 15,
                color: FloralPalette.cocoa,
              ),
              const SizedBox(width: 6),
              Text(
                'Can’t find it? ',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
              Text(
                'Add manually instead',
                style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: FloralPalette.deepRose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the appropriate body content based on state
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasSearched && _results.isEmpty) {
      return _buildZeroResultsState();
    }

    if (_results.isNotEmpty) {
      return _buildResultsList();
    }

    // Default: Initial empty state before search
    return _buildInitialEmptyState();
  }

  /// State 1: Initial state before any search
  Widget _buildInitialEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botanical Daisy Doodle motif
            const DaisyDoodle(size: 64, showStem: false),

            const SizedBox(height: 18),

            // Fraunces Heading
            Text(
              'Find Your Next Tale',
              textAlign: TextAlign.center,
              style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal).copyWith(fontSize: 22),
            ),

            const SizedBox(height: 6),

            // Organic pen underline flourish
            const HandDrawnUnderline(width: 140, color: FloralPalette.blushPink),

            const SizedBox(height: 12),

            // In-voice poetic handwritten copy (Caveat / Cocoa)
            Text(
              'search for a title or author to begin ~',
              textAlign: TextAlign.center,
              style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 18),
            ),

            const SizedBox(height: 28),

            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSearchChip('Circe'),
                _buildSearchChip('Fourth Wing'),
                _buildSearchChip('Jane Austen'),
                _buildSearchChip('The Song of Achilles'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestion chip that populates search query
  Widget _buildSearchChip(String label) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _searchController.text = label;
          _onSearchChanged(label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.7), width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search, size: 13, color: FloralPalette.cocoa),
              const SizedBox(width: 5),
              Text(
                label,
                style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// State 2: Zero results found
  Widget _buildZeroResultsState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botanical Tulip Doodle motif
            const TulipDoodle(size: 56, showStem: false),

            const SizedBox(height: 18),

            // Fraunces Heading
            Text(
              'No Stories Found',
              textAlign: TextAlign.center,
              style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal).copyWith(fontSize: 22),
            ),

            const SizedBox(height: 6),

            // Organic pen underline flourish
            const HandDrawnUnderline(width: 120, color: FloralPalette.latte),

            const SizedBox(height: 12),

            // In-voice poetic handwritten copy (Caveat / Cocoa)
            Text(
              'no matches found, but you can still add it by hand ~',
              textAlign: TextAlign.center,
              style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 18),
            ),

            const SizedBox(height: 24),

            // Prominent "Add Manually Instead" action button
            ElevatedButton.icon(
              key: const ValueKey('zero_results_add_manually_btn'),
              onPressed: () => _openManualEntry(),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Add Manually Instead'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// State 3: Loading in flight
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              valueColor: AlwaysStoppedAnimation<Color>(FloralPalette.deepRose),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'leafing through library shelves... ~',
            style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 17),
          ),
        ],
      ),
    );
  }

  /// State 4: Results List
  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  /// Result card styled to match the existing floral journal card design
  Widget _buildResultCard(BookSearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
        boxShadow: const [FloralPalette.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openManualEntry(result),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Thumbnail cover or placeholder
                Container(
                  width: 52,
                  height: 76,
                  decoration: BoxDecoration(
                    color: FloralPalette.blushPink.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: result.coverUrl != null && result.coverUrl!.isNotEmpty
                        ? Image.network(
                            result.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: PoppyDoodle(size: 24, showStem: false),
                            ),
                          )
                        : const Center(
                            child: PoppyDoodle(size: 24, showStem: false),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Title, Author, Page count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.authors.isNotEmpty ? result.authors.join(', ') : 'Unknown Author',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                          fontSize: 13,
                        ),
                      ),
                      if (result.pageCount != null && result.pageCount! > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FloralPalette.latte.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${result.pageCount} pages',
                            style: JournalTypography.bodySmall(color: FloralPalette.espresso).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Selection chevron
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: FloralPalette.blushPink.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: FloralPalette.deepRose,
                    size: 18,
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
