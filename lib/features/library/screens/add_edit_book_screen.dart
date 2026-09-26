import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/apple_centered_field.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/floral_rating_bar.dart';
import '../../../doodles/bookmark_ribbon_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../models/book.dart';
import '../../../services/image_service.dart';
import '../widgets/book_cover_thumbnail.dart';

/// Step 4c: Handcrafted Botanical Add / Edit Book Form Screen.
///
/// Features:
/// - Reusable for both Add (new book) and Edit (existing book) modes
/// - Supports prefilled drafts for future Book Search (Phase 6)
/// - Cover Image Upload: Photo picker from device, automatic 600px downscaling,
///   80% JPEG compression (30KB-70KB), with Change and Remove actions
/// - Half-step rating input (0 to 5 in 0.5 increments) with tap-half detection & clear button
/// - Favorite Quotes editor: Add, edit, and delete quotes with optional page numbers
/// - Grouped cards: Cover, Title/Authors, Status, Dates, Rating, Genres, Page Count, Notes, Quotes
/// - Custom botanical styling with soft pink shadows and latte hairline dividers
/// - iOS Safari safe: 16px+ inputs (no zoom on focus), keyboard avoidance, >=44px tap targets
/// - Unsaved changes confirmation dialog on back/swipe
/// - Duplicate warning, graceful error handling, and delete action in edit mode
class AddEditBookScreen extends ConsumerStatefulWidget {
  /// Tracks whether an add/edit form is actively open so app-resume recovery never disrupts an in-progress edit session.
  static bool isFormActive = false;

  final Book? bookToEdit;
  final ReadingStatus? defaultStatus;
  final Book? prefilledDraft;

  const AddEditBookScreen({
    super.key,
    this.bookToEdit,
    this.defaultStatus,
    this.prefilledDraft,
  });

  bool get isEditMode => bookToEdit != null;

  @override
  ConsumerState<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends ConsumerState<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _authorsController;
  late final TextEditingController _pageCountController;
  late final TextEditingController _notesController;

  // Form State
  late ReadingStatus _status;
  DateTime? _startDate;
  DateTime? _finishDate;
  double? _rating;
  Uint8List? _coverBytes;
  String? _existingCoverUrl;
  final Set<String> _selectedGenres = {};
  late List<BookQuote> _quotes;
  bool _isSaving = false;
  String? _dateValidationError;

  // Suggested botanical genre tags
  static const List<String> _suggestedGenres = [
    'Fantasy',
    'Romance',
    'Mystery',
    'Historical Fiction',
    'Classic',
    'Sci-Fi',
    'Non-fiction',
    'Poetry',
    'Thriller',
    'Young Adult',
    'Mythology',
    'Drama',
  ];

  // Initial values snapshot to detect unsaved changes
  late final String _initialTitle;
  late final String _initialAuthors;
  late final ReadingStatus _initialStatus;
  late final DateTime? _initialStartDate;
  late final DateTime? _initialFinishDate;
  late final double? _initialRating;
  late final Uint8List? _initialCoverBytes;
  late final Set<String> _initialGenres;
  late final String _initialPageCount;
  late final String _initialNotes;
  late final int _initialQuotesCount;

  @override
  void initState() {
    super.initState();
    AddEditBookScreen.isFormActive = true;

    final source = widget.bookToEdit ?? widget.prefilledDraft;

    _titleController = TextEditingController(text: source?.title ?? '');
    _authorsController = TextEditingController(
      text: source != null ? source.authors.join(', ') : '',
    );
    _pageCountController = TextEditingController(
      text: source?.pageCount != null ? source!.pageCount.toString() : '',
    );
    _notesController = TextEditingController(text: source?.notes ?? '');

    _status = widget.bookToEdit?.status ??
        widget.prefilledDraft?.status ??
        widget.defaultStatus ??
        ReadingStatus.reading;

    _startDate = source?.startDate;
    _finishDate = source?.finishDate;
    _rating = source?.rating;
    _coverBytes = source?.coverBytes;
    _existingCoverUrl = source?.coverUrl;

    _quotes = source != null ? List<BookQuote>.from(source.quotes) : [];

    if (source != null) {
      _selectedGenres.addAll(source.genres);
    }

    // Default dates on initial load if adding new book
    if (widget.bookToEdit == null && widget.prefilledDraft == null) {
      if (_status == ReadingStatus.reading && _startDate == null) {
        _startDate = DateTime.now();
      } else if (_status == ReadingStatus.finished) {
        _startDate ??= DateTime.now();
        _finishDate ??= DateTime.now();
      }
    }

    // Snapshot for dirty checking
    _initialTitle = _titleController.text;
    _initialAuthors = _authorsController.text;
    _initialStatus = _status;
    _initialStartDate = _startDate;
    _initialFinishDate = _finishDate;
    _initialRating = _rating;
    _initialCoverBytes = _coverBytes;
    _initialGenres = Set.from(_selectedGenres);
    _initialPageCount = _pageCountController.text;
    _initialNotes = _notesController.text;
    _initialQuotesCount = _quotes.length;
  }

  @override
  void dispose() {
    AddEditBookScreen.isFormActive = false;
    _titleController.dispose();
    _authorsController.dispose();
    _pageCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Whether user has made any unsaved edits
  bool get _hasUnsavedChanges {
    if (_titleController.text != _initialTitle) return true;
    if (_authorsController.text != _initialAuthors) return true;
    if (_status != _initialStatus) return true;
    if (_startDate != _initialStartDate) return true;
    if (_finishDate != _initialFinishDate) return true;
    if (_rating != _initialRating) return true;
    if (_coverBytes != _initialCoverBytes) return true;
    if (_pageCountController.text != _initialPageCount) return true;
    if (_notesController.text != _initialNotes) return true;
    if (_quotes.length != _initialQuotesCount) return true;
    if (!_areSetsEqual(_selectedGenres, _initialGenres)) return true;
    return false;
  }

  bool _areSetsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  /// Parse authors from comma-separated input
  List<String> _parseAuthors(String input) {
    return input
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  /// Pick cover photo from device with automatic 600px downscaling & 80% JPEG compression
  Future<void> _pickCoverImage() async {
    try {
      final processedBytes = await ImageService.pickAndProcessCoverImage();
      if (processedBytes != null && mounted) {
        setState(() {
          _coverBytes = processedBytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to process photo: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Remove custom cover photo (reverts to poppy placeholder)
  void _removeCoverImage() {
    setState(() {
      _coverBytes = null;
      _existingCoverUrl = null;
    });
  }

  /// Updates status with smart date defaulting
  void _onStatusChanged(ReadingStatus newStatus) {
    setState(() {
      _status = newStatus;
      _dateValidationError = null;

      if (newStatus == ReadingStatus.reading && _startDate == null) {
        _startDate = DateTime.now();
      } else if (newStatus == ReadingStatus.finished) {
        _startDate ??= DateTime.now();
        _finishDate ??= DateTime.now();
      }

      _validateDates();
    });
  }

  /// Validate finish date is not before start date
  bool _validateDates() {
    if (_status == ReadingStatus.finished && _startDate != null && _finishDate != null) {
      final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final finishDay = DateTime(_finishDate!.year, _finishDate!.month, _finishDate!.day);
      if (finishDay.isBefore(startDay)) {
        setState(() {
          _dateValidationError = 'Finish date cannot be earlier than start date ~';
        });
        return false;
      }
    }
    setState(() {
      _dateValidationError = null;
    });
    return true;
  }

  /// Palette-themed date picker modal
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_finishDate ?? _startDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _finishDate = picked;
        }
        _validateDates();
      });
    }
  }

  /// Add custom genre chip
  Future<void> _showAddCustomGenreDialog() async {
    final controller = TextEditingController();
    final newGenre = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FloralPalette.softIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Custom Genre',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(fontSize: 16, color: FloralPalette.warmCharcoal),
            decoration: const InputDecoration(
              hintText: 'e.g. Dystopian, Memoir, Gothic',
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (val) => Navigator.of(context).pop(val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Genre'),
            ),
          ],
        );
      },
    );

    if (newGenre != null && newGenre.isNotEmpty) {
      setState(() {
        _selectedGenres.add(newGenre);
      });
    }
  }

  /// Add / Edit favorite quote modal
  Future<void> _showQuoteDialog({BookQuote? existingQuote, int? editIndex}) async {
    final quoteController = TextEditingController(text: existingQuote?.quote ?? '');
    final pageController = TextEditingController(
      text: existingQuote?.pageNumber != null ? existingQuote!.pageNumber.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final savedQuote = await showDialog<BookQuote>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FloralPalette.softIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            existingQuote != null ? 'Edit Favorite Quote' : 'Add Favorite Quote',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quote Text *',
                    style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('quote_text_input'),
                    controller: quoteController,
                    maxLines: 4,
                    autofocus: true,
                    style: TextStyle(fontSize: 16, color: FloralPalette.warmCharcoal),
                    decoration: const InputDecoration(
                      hintText: '“The words that took your breath away...”',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the quote text';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Page Number (Optional)',
                    style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const ValueKey('quote_page_input'),
                    controller: pageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: 16, color: FloralPalette.warmCharcoal),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 184',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final pageNum = int.tryParse(pageController.text.trim());
                  final quoteObj = BookQuote(
                    id: existingQuote?.id ?? 'quote-${DateTime.now().millisecondsSinceEpoch}',
                    quote: quoteController.text.trim(),
                    pageNumber: pageNum,
                    createdAt: existingQuote?.createdAt ?? DateTime.now(),
                  );
                  Navigator.of(context).pop(quoteObj);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Quote'),
            ),
          ],
        );
      },
    );

    if (savedQuote != null && mounted) {
      setState(() {
        if (editIndex != null) {
          _quotes[editIndex] = savedQuote;
        } else {
          _quotes.add(savedQuote);
        }
      });
    }
  }

  /// Discard changes confirmation dialog
  Future<bool> _handlePopRequest() async {
    if (!_hasUnsavedChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FloralPalette.softIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Discard Changes?',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
          ),
          content: Text(
            'You have unsaved changes to this story. Are you sure you want to discard them?',
            style: JournalTypography.body(color: FloralPalette.warmCharcoal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Editing',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return discard ?? false;
  }

  /// Delete book confirmation dialog (in Edit mode)
  Future<void> _confirmDeleteBook() async {
    final book = widget.bookToEdit;
    if (book == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FloralPalette.softIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Remove from Shelf?',
            style: JournalTypography.headingSmall(color: FloralPalette.poppyRedDark),
          ),
          content: Text(
            'Are you sure you want to remove "${book.title}" from your journal? This cannot be undone.',
            style: JournalTypography.body(color: FloralPalette.warmCharcoal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Keep Book',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.poppyRedDark,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(booksProvider.notifier).deleteBook(book.id);

        if (mounted) {
          // Pop both Edit screen and Detail screen to return to Library
          Navigator.of(context).popUntil((route) => route.isFirst);

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${book.title}" removed from your shelf'),
              backgroundColor: FloralPalette.warmCharcoal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to delete book: $e'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  /// Save / Update book submission
  Future<void> _submitForm() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;
    if (!_validateDates()) return;

    final trimmedTitle = _titleController.text.trim();
    final authorsList = _parseAuthors(_authorsController.text);

    if (trimmedTitle.isEmpty || authorsList.isEmpty) return;

    // Check for duplicates (same title and author, case-insensitive)
    final allBooks = ref.read(booksProvider).value ?? [];
    final isDuplicate = allBooks.any((b) {
      if (widget.bookToEdit != null && b.id == widget.bookToEdit!.id) {
        return false;
      }
      final titleMatch = b.title.trim().toLowerCase() == trimmedTitle.toLowerCase();
      final authorMatch = b.authors.any(
        (a) => authorsList.any((na) => na.toLowerCase() == a.trim().toLowerCase()),
      );
      return titleMatch && authorMatch;
    });

    if (isDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: FloralPalette.softIvory,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text(
              'Book Already on Shelf',
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
            ),
            content: Text(
              'A story titled "$trimmedTitle" by ${authorsList.join(", ")} is already in your journal. Do you want to save another copy?',
              style: JournalTypography.body(color: FloralPalette.warmCharcoal),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FloralPalette.deepRose,
                  foregroundColor: FloralPalette.softIvory,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Anyway'),
              ),
            ],
          );
        },
      );

      if (proceed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final int? pageCount = int.tryParse(_pageCountController.text.trim());
      final existingBook = widget.bookToEdit;

      final bookToSave = Book(
        id: existingBook?.id ?? 'book-${DateTime.now().millisecondsSinceEpoch}',
        title: trimmedTitle,
        authors: authorsList,
        coverUrl: _existingCoverUrl,
        coverBytes: _coverBytes,
        genres: _selectedGenres.toList(),
        rating: _rating,
        startDate: _status == ReadingStatus.wantToRead ? null : _startDate,
        finishDate: (_status == ReadingStatus.finished || _status == ReadingStatus.paused)
            ? _finishDate
            : null,
        status: _status,
        notes: _notesController.text.trim(),
        quotes: _quotes,
        pageCount: pageCount,
        dateAdded: existingBook?.dateAdded ?? DateTime.now(),
      );

      if (widget.isEditMode) {
        await ref.read(booksProvider.notifier).updateBook(bookToSave);
      } else {
        await ref.read(booksProvider.notifier).addBook(bookToSave);
      }

      if (mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Changes saved to "$trimmedTitle" ✨'
                  : '"$trimmedTitle" added to your shelf ✨',
            ),
            backgroundColor: FloralPalette.deepRose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save story: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDisplayDate(DateTime? dt) {
    if (dt == null) return 'Select date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handlePopRequest();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: FloralPalette.petalWhite,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Stack(
                children: [


                  Column(
                    children: [
                      // Top Botanical Nav Bar
                      _buildTopBar(context),

                      // Form Body (Scrollable with keyboard avoidance)
                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Subtitle Header
                                Text(
                                  widget.isEditMode ? 'Edit Book' : 'Add New Book',
                                  style: JournalTypography.headingLarge(
                                    color: FloralPalette.warmCharcoal,
                                  ).copyWith(fontSize: 28),
                                ),
                                const SizedBox(height: 2),
                                const HandDrawnUnderline(width: 95, color: FloralPalette.deepRose),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isEditMode
                                      ? '• update details in your reading journal'
                                      : '• welcome a new story to your shelf',
                                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                                ),

                                const SizedBox(height: 18),

                                // Card 0: Cover Photo Upload & Preview
                                _buildCoverUploadCard(),

                                const SizedBox(height: 16),

                                // Card 1: Title & Author(s)
                                _buildTitleAuthorCard(),

                                const SizedBox(height: 16),

                                // Card 2: Status Chips
                                _buildStatusCard(),

                                // Card 3: Reading Dates (Hidden for Want to Read)
                                if (_status != ReadingStatus.wantToRead) ...[
                                  const SizedBox(height: 16),
                                  _buildDatesCard(),
                                ],

                                const SizedBox(height: 16),

                                // Card 4: Rating Input (Half-star supported)
                                _buildRatingCard(),

                                const SizedBox(height: 16),

                                // Card 5: Genres Multi-Select
                                _buildGenresCard(),

                                const SizedBox(height: 16),

                                // Card 6: Page Count
                                _buildPageCountCard(),

                                const SizedBox(height: 16),

                                // Card 7: Personal Notes
                                _buildNotesCard(),

                                const SizedBox(height: 16),

                                // Card 8: Favorite Quotes Editor
                                _buildQuotesCard(),

                                // In Edit Mode: Delete Action
                                if (widget.isEditMode) ...[
                                  const SizedBox(height: 24),
                                  _buildDeleteAction(),
                                ],

                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Fixed Bottom Bar with Save Button (Tap target >= 48px)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomSaveBar(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top app bar with guaranteed 44x44 tap target
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back / Discard Button
          Material(
            color: FloralPalette.softIvory,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const ValueKey('add_edit_back_btn'),
              onTap: () async {
                final shouldPop = await _handlePopRequest();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2DED9), width: 1.0),
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

          // Central Label
          Text(
            'BOOKMARK • JOURNAL ENTRY',
            style: JournalTypography.bodySmall(
              color: FloralPalette.deepForestGreen,
            ).copyWith(
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),

          // Botanical Header Poppy: Beautifully framed in a 44x44 container, never cut off!
          const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: PoppyDoodle(
                size: 38,
                showStem: false,
                petalColor: FloralPalette.rosePetal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 0: Cover Photo Upload with Preview & Change/Remove actions
  Widget _buildCoverUploadCard() {
    final bool hasCustomCover = _coverBytes != null || (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cover Preview (or poppy placeholder)
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x224A3F44),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _coverBytes != null
                  ? Image.memory(
                      _coverBytes!,
                      fit: BoxFit.cover,
                      width: 80,
                      height: 120,
                    )
                  : (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty)
                      ? Image.network(
                          _existingCoverUrl!,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
            ),
          ),

          const SizedBox(width: 18),

          // Action Buttons: Pick Photo & Remove
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book Cover',
                  style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCustomCover ? 'Custom photo attached' : 'Botanical placeholder active',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Upload / Change Button (Tap target >= 44px)
                ElevatedButton.icon(
                  key: const ValueKey('pick_cover_btn'),
                  onPressed: _pickCoverImage,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text(hasCustomCover ? 'Change Cover' : 'Upload Cover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FloralPalette.blushPink,
                    foregroundColor: FloralPalette.deepRose,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(130, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                if (hasCustomCover) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const ValueKey('remove_cover_btn'),
                    onPressed: _removeCoverImage,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: FloralPalette.cocoa),
                    label: Text(
                      'Remove Custom Cover',
                      style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Book';
    final dummyBook = Book(
      id: 'preview',
      title: title,
      authors: const [],
      dateAdded: DateTime.now(),
    );
    return BookCoverThumbnail(
      book: dummyBook,
      width: 80,
      height: 120,
      borderRadius: 10,
    );
  }

  /// Card 1: Title & Author(s) Inputs (16px+ for iOS Safari)
  Widget _buildTitleAuthorCard() {
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
          Text(
            'Book Title *',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          AppleCenteredTextFormField(
            fieldKey: const ValueKey('input_book_title'),
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FloralPalette.warmCharcoal,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter title (e.g. Pride and Prejudice)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the book title';
              }
              return null;
            },
            onChanged: (_) => setState(() {}), // Refreshes placeholder cover preview
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Author(s) *',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'separate multiple with commas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppleCenteredTextFormField(
            fieldKey: const ValueKey('input_book_authors'),
            controller: _authorsController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: 16,
              color: FloralPalette.warmCharcoal,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Jane Austen, or Author 1, Author 2',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter at least one author';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Card 2: Reading Status Choice Chips (Tap targets >= 44px)
  Widget _buildStatusCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Status',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'palette choice',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReadingStatus.values.map((status) {
              final isSelected = _status == status;
              final pillStyle = StatusPillStyle.of(status);

              final Color bg = isSelected ? pillStyle.fill : FloralPalette.softIvory;
              final Color text = isSelected ? pillStyle.text : FloralPalette.warmCharcoal;
              final Color border = isSelected ? pillStyle.border : FloralPalette.cardBorder;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('status_select_${status.name}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onStatusChanged(status),
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

  /// Card 3: Reading Dates (Themed Date Pickers, Tap targets >= 44px)
  Widget _buildDatesCard() {
    final showFinish = _status == ReadingStatus.finished || _status == ReadingStatus.paused;

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
                'Reading Dates',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Start Date Button
          _buildDatePickerTile(
            key: const ValueKey('pick_start_date_btn'),
            label: 'Start Date',
            date: _startDate,
            onTap: () => _pickDate(isStart: true),
            onClear: () {
              setState(() {
                _startDate = null;
                _validateDates();
              });
            },
          ),

          // Finish Date Button (Visible for Finished / Paused)
          if (showFinish) ...[
            const SizedBox(height: 10),
            _buildDatePickerTile(
              key: const ValueKey('pick_finish_date_btn'),
              label: 'Finish Date',
              date: _finishDate,
              onTap: () => _pickDate(isStart: false),
              onClear: () {
                setState(() {
                  _finishDate = null;
                  _validateDates();
                });
              },
            ),
          ],

          if (_dateValidationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _dateValidationError!,
              style: JournalTypography.bodySmall(color: FloralPalette.poppyRedDark).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePickerTile({
    required Key key,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Material(
      color: FloralPalette.petalWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 18,
                  color: date != null ? FloralPalette.deepRose : FloralPalette.latte,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDisplayDate(date),
                  style: JournalTypography.bodySmall(
                    color: date != null ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
                  ).copyWith(
                    fontWeight: date != null ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 16, color: FloralPalette.cocoa),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Card 4: Rating Input with Half-Star support (Tap targets >= 44px)
  Widget _buildRatingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: FloralRatingBar(
        rating: _rating,
        showLabel: true,
        showClearButton: true,
        blossomSize: 34,
        spacing: 12,
        onRatingChanged: (newRating) => setState(() => _rating = newRating),
      ),
    );
  }

  Widget _buildGenresCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Genres & Tropes',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'select all that apply',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._suggestedGenres.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return _buildGenreChip(genre, isSelected);
              }),
              ..._selectedGenres
                  .where((g) => !_suggestedGenres.contains(g))
                  .map((customGenre) => _buildGenreChip(customGenre, true)),

              // "+ Add your own" Chip
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const ValueKey('add_custom_genre_btn'),
                  onTap: _showAddCustomGenreDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: FloralPalette.kraftPaper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FloralPalette.latte, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, size: 16, color: FloralPalette.cocoa),
                          const SizedBox(width: 4),
                          Text(
                            'Add your own',
                            style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildGenreChip(String genre, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('genre_chip_$genre'),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedGenres.remove(genre);
            } else {
              _selectedGenres.add(genre);
            }
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? FloralPalette.deepRose
                  : FloralPalette.blushPink.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? FloralPalette.deepRose : const Color(0xFFF0DCD7),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    genre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JournalTypography.bodySmall(
                      color: isSelected ? Colors.white : FloralPalette.warmCharcoal,
                    ).copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
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

  /// Card 6: Page Count (Numeric keyboard, 16px font)
  Widget _buildPageCountCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page Count (Optional)',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'for reading stats',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppleCenteredTextFormField(
            fieldKey: const ValueKey('input_page_count'),
            controller: _pageCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 16,
              color: FloralPalette.warmCharcoal,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. 384',
              prefixIcon: Icon(Icons.auto_stories_outlined, color: FloralPalette.cocoa, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Card 7: Personal Notes
  Widget _buildNotesCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Notes & Reflections',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'private journal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppleCenteredTextFormField(
            fieldKey: const ValueKey('input_book_notes'),
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(
              fontSize: 16,
              color: FloralPalette.warmCharcoal,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: 'Thoughts, marginalia, feelings while reading...',
            ),
          ),
        ],
      ),
    );
  }

  /// Card 8: Favorite Quotes Editor (Add / Edit / Delete)
  Widget _buildQuotesCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite Quotes',
                style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 15),
              ),
              Flexible(
                child: Text(
                  'cherished lines',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(color: FloralPalette.cocoa),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quotes List
          if (_quotes.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FloralPalette.kraftPaper.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FloralPalette.latte.withValues(alpha: 0.7), width: 0.8),
              ),
              child: Text(
                'No quotes yet ~',
                style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
              ),
            ),
          ] else ...[
            ..._quotes.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FloralPalette.kraftPaper,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FloralPalette.latte, width: 1.0),
                  boxShadow: [FloralPalette.cardShadow],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      top: -14,
                      right: 6,
                      child: BookmarkRibbonDoodle(width: 12, height: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.displayQuote,
                          style: JournalTypography.body(color: FloralPalette.cocoa).copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        if (q.pageNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '— page ${q.pageNumber}',
                            style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              key: ValueKey('edit_quote_btn_$idx'),
                              onTap: () => _showQuoteDialog(existingQuote: q, editIndex: idx),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.edit_outlined, size: 16, color: FloralPalette.cocoa),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              key: ValueKey('delete_quote_btn_$idx'),
                              onTap: () {
                                setState(() {
                                  _quotes.removeAt(idx);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.delete_outline_rounded, size: 16, color: FloralPalette.poppyRedDark),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 10),

          // "+ Add Favorite Quote" Button (Tap target >= 44px)
          OutlinedButton.icon(
            key: const ValueKey('add_quote_btn'),
            onPressed: () => _showQuoteDialog(),
            icon: const Icon(Icons.format_quote_rounded, size: 18, color: FloralPalette.cocoa),
            label: Text(
              'Add Favorite Quote',
              style: JournalTypography.bodySmall(color: FloralPalette.cocoa).copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: FloralPalette.latte, width: 1.0),
              backgroundColor: FloralPalette.kraftPaper.withValues(alpha: 0.5),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  /// Delete Action in Edit Mode
  Widget _buildDeleteAction() {
    return Center(
      child: OutlinedButton.icon(
        key: const ValueKey('delete_book_btn'),
        onPressed: _confirmDeleteBook,
        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: FloralPalette.poppyRedDark),
        label: Text(
          'Delete Book from Shelf',
          style: JournalTypography.bodySmall(color: FloralPalette.poppyRedDark).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFF2B8B8), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(200, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  /// Fixed Bottom Save Bar (Safe area bottom respected, tap target >= 48px)
  Widget _buildBottomSaveBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        math.max(16.0, MediaQuery.of(context).padding.bottom + 8.0),
      ),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        border: Border(top: BorderSide(color: FloralPalette.latte.withValues(alpha: 0.6), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        key: const ValueKey('save_book_btn'),
        onPressed: _isSaving ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: FloralPalette.deepRose,
          foregroundColor: FloralPalette.softIvory,
          disabledBackgroundColor: FloralPalette.deepRose.withValues(alpha: 0.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: _isSaving
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: FloralPalette.softIvory,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                widget.isEditMode ? 'Save Changes' : 'Add to Shelf',
                style: JournalTypography.subheading(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontStyle: FontStyle.normal,
                ),
              ),
      ),
    );
  }
}
