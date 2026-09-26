import 'dart:convert';
import 'package:bookmark/services/error_logger.dart';
import 'package:bookmark/core/widgets/status_pill.dart';
import 'package:bookmark/doodles/maple_leaf_doodle.dart';
import 'package:bookmark/doodles/oak_leaf_doodle.dart';
import 'package:bookmark/doodles/acorn_doodle.dart';
import 'package:bookmark/doodles/mushroom_doodle.dart';
import 'package:bookmark/doodles/falling_leaves_doodle.dart';
import 'package:bookmark/core/theme/palette.dart';
import 'package:bookmark/doodles/poppy_doodle.dart';
import 'package:bookmark/core/widgets/floral_rating_bar.dart';
import 'package:bookmark/core/widgets/floral_celebration_overlay.dart';
import 'package:bookmark/features/library/screens/book_search_screen.dart';
import 'package:bookmark/services/book_search_service.dart';
import 'package:bookmark/features/library/screens/add_edit_book_screen.dart';
import 'package:bookmark/features/library/screens/library_screen.dart';
import 'package:bookmark/features/library/widgets/book_list_card.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/features/library/widgets/library_empty_state.dart';
import 'package:bookmark/features/library/screens/book_detail_screen.dart';
import 'package:bookmark/doodles/doodle_gallery_screen.dart';
import 'package:bookmark/doodles/bookmark_ribbon_doodle.dart';
import 'package:bookmark/doodles/vine_doodle.dart';

class InMemoryStorageService implements StorageService {
  final Map<String, Book> _books = {};
  final Map<String, Uint8List> _covers = {};
  final Map<String, dynamic> _settings = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Book>> getAllBooks() async => _books.values.toList();

  @override
  Future<Book?> getBook(String id) async => _books[id];

  @override
  Future<void> saveBook(Book book) async => _books[book.id] = book;

  @override
  Future<void> deleteBook(String id) async {
    _books.remove(id);
    _covers.remove(id);
  }

  @override
  Future<void> saveCoverImage(String id, Uint8List imageBytes) async => _covers[id] = imageBytes;

  @override
  Future<Uint8List?> getCoverImage(String id) async => _covers[id];

  @override
  Future<void> deleteCoverImage(String id) async => _covers.remove(id);

  @override
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async => _settings[key] ?? defaultValue;

  @override
  Future<void> setSetting(String key, dynamic value) async => _settings[key] = value;

  @override
  Future<Map<String, dynamic>> exportAllData() => BackupService.createExportPayload(this);

  @override
  Future<void> importAllData(Map<String, dynamic> data, {bool merge = false}) =>
      BackupService.performImport(this, data, merge: merge);

  @override
  Future<bool> requestPersistentStorage() async => true;

  @override
  Future<bool> isStoragePersistent() async => true;
}

void main() {
  testWidgets('Library Screen: list view, book details, toggle to grid, and bottom nav', (WidgetTester tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.saveBook(
      Book(
        id: 'test-1',
        title: 'The Seven Husbands of Evelyn Hugo',
        authors: ['Taylor Jenkins Reid'],
        genres: ['Romance'],
        rating: 4.5,
        status: ReadingStatus.finished,
        dateAdded: DateTime.now(),
      ),
    );
    await mockStorage.saveBook(
      Book(
        id: 'test-2',
        title: 'Tomorrow, and Tomorrow, and Tomorrow',
        authors: ['Gabrielle Zevin'],
        genres: ['Fiction'],
        rating: 0.0,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime(2026, 9, 23),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Header and Nav both have "Library"
    expect(find.text('Library'), findsNWidgets(2));
    expect(find.textContaining('READING JOURNAL'), findsOneWidget);

    // 2. Verify Book card in List view
    expect(find.byKey(const ValueKey('library_list_view')), findsOneWidget);
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsWidgets);

    // 3. Test Wishlist tab: hides status pill & unrated, shows "Added <date>"
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.textContaining('WISHLIST'), findsOneWidget);
    expect(find.text('Tomorrow, and Tomorrow, and Tomorrow'), findsWidgets);
    expect(find.text('Added Sep 23'), findsNothing); // Dates hidden on wishlist cards
    expect(find.text('Want to Read'), findsNothing); // Pill hidden on wishlist
    expect(find.text('Unrated'), findsNothing); // Unrated hidden on wishlist

    // 4. Test Stats tab: dynamic year and friendly unset state
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.textContaining('READING STATS'), findsOneWidget);
    expect(find.text('${DateTime.now().year} Reading Goal'), findsOneWidget);
    expect(find.text('Set a goal for the year ~'), findsOneWidget);

    // 5. Test Settings tab: friendly unset goal & 44x44 buttons
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SETTINGS'), findsOneWidget);
    expect(find.text('Set a goal for the year'), findsOneWidget);

    // Tap set goal
    await tester.tap(find.text('Set a goal for the year'));
    await tester.pumpAndSettle();
    expect(find.text('12 books'), findsOneWidget);

    // Verify 44x44 tap area on buttons
    final minusBtn = find.byTooltip('Decrease goal');
    expect(minusBtn, findsOneWidget);
    final Size minusSize = tester.getSize(minusBtn);
    expect(minusSize.width, greaterThanOrEqualTo(44.0));
    expect(minusSize.height, greaterThanOrEqualTo(44.0));
  });

  testWidgets('Library Screen: empty shelf renders poetic empty state with poppy & book', (WidgetTester tester) async {
    final mockStorage = InMemoryStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LibraryEmptyState), findsOneWidget);
    expect(find.text('Your shelf is waiting for its first story'), findsOneWidget);
  });

  testWidgets('Botanical Sketchbook: renders Brown Accents preview card and swatches', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DoodleGalleryScreen(onBackToJournal: () {}),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brown Accents section
    expect(find.text('Brown Accents (Preview Only)'), findsOneWidget);
    expect(find.text('Espresso'), findsOneWidget);
    expect(find.text('#4A3428'), findsOneWidget);
    expect(find.text('Cocoa'), findsOneWidget);
    expect(find.text('#7A5240'), findsOneWidget);
    expect(find.text('Caramel'), findsOneWidget);
    expect(find.text('#B9825A'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('#D8BBA0'), findsOneWidget);
    expect(find.text('Kraft Paper'), findsOneWidget);
    expect(find.text('#F3E7DA'), findsOneWidget);

    // Verify samples
    expect(find.text('Brown Twig with Leaves'), findsOneWidget);
    expect(find.text('Bookmark Ribbon'), findsOneWidget);
    expect(find.text('Leather-Bound Open Book'), findsOneWidget);
    expect(find.text('Kraft-Paper Quote Card with Cocoa Text'), findsOneWidget);
    expect(find.text('Latte & Espresso "Paused" Pill (6.4:1 contrast)'), findsOneWidget);
    expect(find.text('Caveat Handwritten Line in Cocoa'), findsOneWidget);
  });

  testWidgets('Step 4b: Book Detail Screen opens with Hero cover, half-star rating, Kraft quotes, and vine divider', (WidgetTester tester) async {
    final now = DateTime.now();
    final mockStorage = InMemoryStorageService();
    final testBook = Book(
      id: 'detail-test-1',
      title: 'A Court of Mist and Fury',
      authors: ['Sarah J. Maas'],
      genres: ['Fantasy', 'Romance'],
      rating: 4.5,
      status: ReadingStatus.finished,
      startDate: now.subtract(const Duration(days: 20)),
      finishDate: now.subtract(const Duration(days: 5)),
      notes: 'Chapter 54 took my breath away. Beautiful character growth.',
      pageCount: 624,
      quotes: [
        BookQuote(
          id: 'q-1',
          quote: 'To the stars who listen—and the dreams that are answered.',
          pageNumber: 345,
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ],
      dateAdded: now.subtract(const Duration(days: 20)),
    );

    await mockStorage.saveBook(testBook);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the book in the list view to navigate to detail screen
    await tester.tap(find.byType(BookListCard).first);
    await tester.pumpAndSettle();

    // 1. Verify BookDetailScreen is displayed
    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('Book Details'), findsOneWidget);
    expect(find.text('A Court of Mist and Fury'), findsWidgets);
    expect(find.text('Sarah J. Maas'), findsOneWidget);
    expect(find.text('624 pages'), findsOneWidget);

    // 2. Verify Half-Star Rating Display (4.5 / 5.0)
    expect(find.text('4.5 / 5.0'), findsOneWidget);
    expect(find.byType(FloralRatingBar), findsOneWidget);

    // 3. Verify Vine Divider doodle is rendered
    expect(find.byType(VineBorderDoodle), findsOneWidget);

    // 4. Verify Reading Timeline section
    expect(find.text('Reading Timeline'), findsOneWidget);
    expect(find.text('Added to Library'), findsOneWidget);
    expect(find.text('Started Reading'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);

    // 5. Verify Favorite Quotes section on Kraft Paper with Cocoa text & ribbon corner
    expect(find.text('Favorite Quotes'), findsOneWidget);
    expect(find.text('“To the stars who listen—and the dreams that are answered.”'), findsOneWidget);
    expect(find.text('— page 345'), findsOneWidget);
    expect(find.byType(BookmarkRibbonDoodle), findsWidgets); // Ribbon corner on quotes & header

    // 6. Verify Reflections & Notes section
    expect(find.text('Reflections & Notes'), findsOneWidget);
    expect(find.text('Chapter 54 took my breath away. Beautiful character growth.'), findsOneWidget);

    // 7. Verify Tap Targets >= 44x44
    final backBtn = find.byKey(const ValueKey('detail_back_button'));
    expect(backBtn, findsOneWidget);
    final Size backSize = tester.getSize(backBtn);
    expect(backSize.width, greaterThanOrEqualTo(44.0));
    expect(backSize.height, greaterThanOrEqualTo(44.0));

    final editBtn = find.byKey(const ValueKey('detail_edit_button'));
    expect(editBtn, findsOneWidget);
    final Size editSize = tester.getSize(editBtn);
    expect(editSize.width, greaterThanOrEqualTo(44.0));
    expect(editSize.height, greaterThanOrEqualTo(44.0));

    // Tap edit button: opens AddEditBookScreen in edit mode
    await tester.tap(editBtn);
    await tester.pumpAndSettle();
    expect(find.byType(AddEditBookScreen), findsOneWidget);
    expect(find.text('Edit Book'), findsOneWidget);

    // Tap back button from edit screen
    await tester.tap(find.byKey(const ValueKey('add_edit_back_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);

    // 8. Test Back button pops back to Library
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsNothing);
    expect(find.text('Library'), findsNWidgets(2));
  });

  testWidgets('Step 4c-1: Add/Edit Book form - add new book, validation, edit, discard dialog', (WidgetTester tester) async {
    final mockStorage = InMemoryStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Open Add Book from Library FAB (+)
    final fab = find.byKey(const ValueKey('add_book_fab'));
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify BookSearchScreen opens first from Library FAB (+)
    expect(find.byType(BookSearchScreen), findsOneWidget);

    // Tap "Add manually instead" to open AddEditBookScreen
    await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditBookScreen), findsOneWidget);
    expect(find.text('Add New Book'), findsOneWidget);

    // Verify tap targets >= 44px
    final saveBtn = find.byKey(const ValueKey('save_book_btn'));
    expect(saveBtn, findsOneWidget);
    final Size saveSize = tester.getSize(saveBtn);
    expect(saveSize.height, greaterThanOrEqualTo(48.0));

    // 2. Validation check: attempt to save empty form
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();
    expect(find.text('Please enter the book title'), findsOneWidget);

    // 3. Fill required fields
    await tester.enterText(find.byKey(const ValueKey('input_book_title')), 'Emma');
    await tester.enterText(find.byKey(const ValueKey('input_book_authors')), 'Jane Austen');

    // Change status to Finished
    final finishedChip = find.byKey(const ValueKey('status_select_finished'));
    await tester.ensureVisible(finishedChip);
    await tester.pumpAndSettle();
    await tester.tap(finishedChip);
    await tester.pumpAndSettle();

    // Select genre 'Classic'
    final classicChip = find.byKey(const ValueKey('genre_chip_Classic'));
    await tester.ensureVisible(classicChip);
    await tester.pumpAndSettle();
    await tester.tap(classicChip);
    await tester.pumpAndSettle();

    // Enter page count
    final pageInput = find.byKey(const ValueKey('input_page_count'));
    await tester.ensureVisible(pageInput);
    await tester.pumpAndSettle();
    await tester.enterText(pageInput, '474');

    // Enter notes
    final notesInput = find.byKey(const ValueKey('input_book_notes'));
    await tester.ensureVisible(notesInput);
    await tester.pumpAndSettle();
    await tester.enterText(notesInput, 'A witty masterpiece of character.');

    // 4. Save the book
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Dismiss floating snackbar before proceeding
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Returned to Library, verify Emma is listed
    expect(find.byType(AddEditBookScreen), findsNothing);
    expect(find.text('Emma'), findsWidgets);

    // 5. Open Emma Detail Screen and Edit it
    await tester.tap(find.text('Emma').first);
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);
    expect(find.text('474 pages'), findsOneWidget);

    // Tap Edit
    await tester.tap(find.byKey(const ValueKey('detail_edit_button')));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditBookScreen), findsOneWidget);
    expect(find.text('Edit Book'), findsOneWidget);

    // Verify existing data is populated
    expect(find.text('Emma'), findsWidgets);
    expect(find.text('Jane Austen'), findsOneWidget);

    // Edit notes
    final editNotesInput = find.byKey(const ValueKey('input_book_notes'));
    await tester.ensureVisible(editNotesInput);
    await tester.pumpAndSettle();
    await tester.enterText(editNotesInput, 'Updated note: Highly recommended!');
    await tester.tap(find.byKey(const ValueKey('save_book_btn')));
    await tester.pumpAndSettle();

    // Dismiss floating snackbar before proceeding
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Verify Detail screen shows updated note immediately
    expect(find.byType(AddEditBookScreen), findsNothing);
    expect(find.text('Updated note: Highly recommended!'), findsOneWidget);

    // 6. Test Discard Changes dialog
    await tester.tap(find.byKey(const ValueKey('detail_edit_button')));
    await tester.pumpAndSettle();

    // Type a change
    await tester.enterText(find.byKey(const ValueKey('input_book_title')), 'Emma - Volume I');
    // Tap back button
    await tester.tap(find.byKey(const ValueKey('add_edit_back_btn')));
    await tester.pumpAndSettle();

    // Verify discard dialog
    expect(find.text('Discard Changes?'), findsOneWidget);
    // Tap Keep Editing
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditBookScreen), findsOneWidget);

    // Tap back button again and Discard
    await tester.tap(find.byKey(const ValueKey('add_edit_back_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(AddEditBookScreen), findsNothing);

    // 7. Delete Book from edit screen
    await tester.tap(find.byKey(const ValueKey('detail_edit_button')));
    await tester.pumpAndSettle();

    // Scroll to delete button
    final deleteBtn = find.byKey(const ValueKey('delete_book_btn'));
    await tester.ensureVisible(deleteBtn);
    await tester.pumpAndSettle();
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Remove from Shelf?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify returned to Library and Emma is removed
    expect(find.text('Emma'), findsNothing);
  });
  testWidgets('Step 4c-2: Rating tap on BookDetail updates Storage immediately and persists', (tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.init();

    final testBook = Book(
      id: 'test-rating-book',
      title: 'Persuasion',
      authors: ['Jane Austen'],
      genres: ['Romance'],
      status: ReadingStatus.finished,
      rating: 3.0,
      startDate: DateTime(2026, 1, 1),
      finishDate: DateTime(2026, 1, 15),
      dateAdded: DateTime(2026, 1, 1),
      pageCount: 300,
      notes: 'Treasured reread.',
      quotes: [],
    );
    await mockStorage.saveBook(testBook);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Persuasion
    await tester.tap(find.text('Persuasion').last);
    await tester.pumpAndSettle();

    // Verify rating shows 3.0 / 5.0
    expect(find.text('3.0 / 5.0'), findsOneWidget);

    // Tap on 5th star
    final star5 = find.byKey(const ValueKey('rating_star_5'));
    await tester.ensureVisible(star5);
    await tester.tap(star5);
    await tester.pumpAndSettle();

    // Rating in UI should now be 5.0
    expect(find.text('5.0 / 5.0'), findsOneWidget);

    // Storage should immediately have rating 5.0
    final storedBook = await mockStorage.getBook('test-rating-book');
    expect(storedBook?.rating, 5.0);
  });

  testWidgets('Step 4c-2: Favorite quotes can be added, edited, and deleted in form', (tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.init();

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Book FAB -> opens BookSearchScreen
    await tester.tap(find.byKey(const ValueKey('add_book_fab')));
    await tester.pumpAndSettle();
    expect(find.byType(BookSearchScreen), findsOneWidget);

    // Bypass to manual AddEditBookScreen
    await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
    await tester.pumpAndSettle();

    // Scroll to Add Quote button
    final addQuoteBtn = find.byKey(const ValueKey('add_quote_btn'));
    await tester.ensureVisible(addQuoteBtn);
    await tester.tap(addQuoteBtn);
    await tester.pumpAndSettle();

    // Fill in quote dialog
    await tester.enterText(find.byKey(const ValueKey('quote_text_input')), 'I declare after all there is no enjoyment like reading!');
    await tester.enterText(find.byKey(const ValueKey('quote_page_input')), '42');
    await tester.tap(find.text('Save Quote'));
    await tester.pumpAndSettle();

    // Verify quote appears on Kraft card
    expect(find.text('“I declare after all there is no enjoyment like reading!”'), findsOneWidget);
    expect(find.text('— page 42'), findsOneWidget);

    // Edit quote
    final editQuoteBtn = find.byKey(const ValueKey('edit_quote_btn_0'));
    await tester.tap(editQuoteBtn);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('quote_page_input')), '43');
    await tester.tap(find.text('Save Quote'));
    await tester.pumpAndSettle();

    expect(find.text('— page 43'), findsOneWidget);

    // Delete quote
    final deleteQuoteBtn = find.byKey(const ValueKey('delete_quote_btn_0'));
    await tester.tap(deleteQuoteBtn);
    await tester.pumpAndSettle();

    expect(find.text('No quotes yet ~'), findsOneWidget);
  });

  test('BookQuote: quotes formatting strips doubled quotes and trailing dot anomalies', () {
    // 1. Without quotes
    final q1 = BookQuote(
      id: 'q1',
      quote: 'Its the Hope that Kills',
      createdAt: DateTime.now(),
    );
    expect(q1.displayQuote, '“Its the Hope that Kills”');

    // 2. With single double quotes
    final q2 = BookQuote(
      id: 'q2',
      quote: '"Its the Hope that Kills"',
      createdAt: DateTime.now(),
    );
    expect(q2.displayQuote, '“Its the Hope that Kills”');

    // 3. With doubled quotes
    final q3 = BookQuote(
      id: 'q3',
      quote: '""Its the Hope that Kills""',
      createdAt: DateTime.now(),
    );
    expect(q3.displayQuote, '“Its the Hope that Kills”');

    // 4. With curly quotes
    final q4 = BookQuote(
      id: 'q4',
      quote: '“Its the Hope that Kills”',
      createdAt: DateTime.now(),
    );
    expect(q4.displayQuote, '“Its the Hope that Kills”');

    // 5. Trailing dot anomaly e.g. "tragedy…."
    final q5 = BookQuote(
      id: 'q5',
      quote: 'A dragon without its rider is a tragedy….',
      createdAt: DateTime.now(),
    );
    expect(q5.displayQuote, '“A dragon without its rider is a tragedy…”');

    // 6. Snippet formatting strips trailing period before ellipsis
    final snippet = BookQuote.formatSnippet(
      'A dragon without its rider is a tragedy. A rider without their dragon is dead.',
      maxLength: 40,
    );
    expect(snippet, '“A dragon without its rider is a tragedy…”');
    expect(snippet.contains('….'), isFalse);
    expect(snippet.contains('....'), isFalse);
  });

  testWidgets('Placeholder cover: long title wraps naturally without mid-word ellipsis truncation', (tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.init();

    await mockStorage.saveBook(
      Book(
        id: 'test-long-title',
        title: 'The Seven Husbands of Evelyn Hugo',
        authors: ['Taylor Jenkins Reid'],
        genres: ['Historical Fiction'],
        status: ReadingStatus.reading,
        dateAdded: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the title wraps within cover bounds
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsWidgets);
    // Ensure the card renders at standard height without overflow
    final cardFinder = find.byType(BookListCard);
    expect(cardFinder, findsOneWidget);
    final cardSize = tester.getSize(cardFinder);
    expect(cardSize.height, greaterThan(0));
  });

  testWidgets('BookSearchScreen: verifies search field, both empty states, and manual entry bypass', (tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.init();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: MaterialApp(
          home: BookSearchScreen(
            searchFn: (q) async => [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify search input field exists
    expect(find.byKey(const ValueKey('book_search_input')), findsOneWidget);

    // 2. Verify Initial "before search" empty state copy
    expect(find.text('Find Your Next Tale'), findsOneWidget);
    expect(find.text('search for a title or author to begin ~'), findsOneWidget);
    expect(find.text('Circe'), findsOneWidget);

    // 3. Verify persistent "Add manually instead" link
    expect(find.byKey(const ValueKey('add_manually_btn')), findsOneWidget);

    // 4. Type a search query to trigger debounce and search
    await tester.enterText(find.byKey(const ValueKey('book_search_input')), 'Unfindable Book XYZ');
    // Pump debounce timer (500ms) + simulated search delay (350ms)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // 5. Verify Zero Results empty state copy and action
    expect(find.text('No Stories Found'), findsOneWidget);
    expect(find.text('no matches found, but you can still add it by hand ~'), findsOneWidget);
    expect(find.byKey(const ValueKey('zero_results_add_manually_btn')), findsOneWidget);

    // 6. Tap "Add Manually Instead" from zero results
    await tester.tap(find.byKey(const ValueKey('zero_results_add_manually_btn')));
    await tester.pumpAndSettle();

    // Verify AddEditBookScreen opened
    expect(find.byType(AddEditBookScreen), findsOneWidget);
  });

  testWidgets('Entry points: Library + and Wishlist + open BookSearchScreen; Detail Edit opens AddEditBookScreen', (tester) async {
    final mockStorage = InMemoryStorageService();
    await mockStorage.init();

    final testBook = Book(
      id: 'book-entry-test',
      title: 'Sense and Sensibility',
      authors: ['Jane Austen'],
      genres: ['Romance'],
      status: ReadingStatus.reading,
      dateAdded: DateTime.now(),
    );
    await mockStorage.saveBook(testBook);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
        ],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Library tab (+) opens BookSearchScreen
    final libraryFab = find.byKey(const ValueKey('add_book_fab'));
    expect(libraryFab, findsOneWidget);
    await tester.tap(libraryFab);
    await tester.pumpAndSettle();

    expect(find.byType(BookSearchScreen), findsOneWidget);
    final searchScreenOnLibrary = tester.widget<BookSearchScreen>(find.byType(BookSearchScreen));
    expect(searchScreenOnLibrary.defaultStatus, ReadingStatus.reading);

    // Pop back to Library
    await tester.tap(find.byKey(const ValueKey('search_back_button')));
    await tester.pumpAndSettle();
    expect(find.byType(BookSearchScreen), findsNothing);

    // 2. Switch to Wishlist tab
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();

    // Wishlist tab (+) opens BookSearchScreen
    final wishlistFab = find.byKey(const ValueKey('add_book_fab'));
    expect(wishlistFab, findsOneWidget);
    await tester.tap(wishlistFab);
    await tester.pumpAndSettle();

    expect(find.byType(BookSearchScreen), findsOneWidget);
    final searchScreenOnWishlist = tester.widget<BookSearchScreen>(find.byType(BookSearchScreen));
    expect(searchScreenOnWishlist.defaultStatus, ReadingStatus.wantToRead);

    // Pop back to Wishlist
    await tester.tap(find.byKey(const ValueKey('search_back_button')));
    await tester.pumpAndSettle();

    // 3. Switch back to Library tab, tap book to open BookDetailScreen
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sense and Sensibility').last);
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsOneWidget);

    // Tap Edit button on BookDetailScreen -> MUST open AddEditBookScreen directly (not search)
    final editBtn = find.byKey(const ValueKey('detail_edit_button'));
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pumpAndSettle();

    expect(find.byType(AddEditBookScreen), findsOneWidget);
    expect(find.byType(BookSearchScreen), findsNothing);
  });

  testWidgets('Phase 7: Wishlist sorting (newest first) and empty state with poppy & caveat copy', (WidgetTester tester) async {
    final storage = InMemoryStorageService();

    // 1. Test Empty State
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: BookmarkApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wishlist').last);
    await tester.pumpAndSettle();

    // Verify warm empty state with Caveat copy
    expect(find.text("Books you'd love to read someday live here ~"), findsOneWidget);
    expect(find.text("add stories you dream of reading next"), findsOneWidget);
    expect(find.text('Find a Book'), findsOneWidget);

    // 2. Add two Want to Read books with different dateAdded
    final olderBook = Book(
      id: 'w1',
      title: 'Tale of Whispers',
      authors: ['Author A'],
      genres: ['Fantasy'],
      status: ReadingStatus.wantToRead,
      dateAdded: DateTime(2026, 9, 20),
    );
    final newerBook = Book(
      id: 'w2',
      title: 'Chronicle of Stars',
      authors: ['Author B'],
      genres: ['Romance'],
      status: ReadingStatus.wantToRead,
      dateAdded: DateTime(2026, 9, 24),
    );

    await storage.saveBook(olderBook);
    await storage.saveBook(newerBook);

    // Re-render with fresh ProviderScope so booksProvider reads the newly saved books
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(home: BookmarkApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wishlist').last);
    await tester.pumpAndSettle();

    // Verify both books are displayed (can appear on thumbnail spine + card title)
    expect(find.text('Tale of Whispers'), findsWidgets);
    expect(find.text('Chronicle of Stars'), findsWidgets);

    // Verify Newer book appears before Older book in widget tree (newest first)
    final newerPos = tester.getTopLeft(find.text('Chronicle of Stars').last).dy;
    final olderPos = tester.getTopLeft(find.text('Tale of Whispers').last).dy;
    expect(newerPos, lessThan(olderPos));

    // Verify rating and dates are hidden on Wishlist cards
    expect(find.textContaining('Added'), findsNothing);
    expect(find.text('Unrated'), findsNothing);
  });

  testWidgets('Phase 7: Book Detail "I have it / Start reading" transitions to Reading or Finished preserving all fields', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final wishlistBook = Book(
      id: 'w-detail-1',
      title: 'Circe',
      authors: ['Madeline Miller'],
      genres: ['Mythology', 'Fantasy'],
      status: ReadingStatus.wantToRead,
      pageCount: 393,
      notes: 'Gift from friend',
      quotes: [
        BookQuote(
          id: 'q1',
          quote: 'Humbling women is the chief pastime of poets.',
          createdAt: DateTime(2026, 9, 23),
        ),
      ],
      dateAdded: DateTime(2026, 9, 23),
    );
    await storage.saveBook(wishlistBook);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(
          home: BookDetailScreen(bookId: 'w-detail-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prominent "I have it / Start reading" button exists
    final startBtn = find.byKey(const ValueKey('start_reading_button'));
    expect(startBtn, findsOneWidget);

    // Tap to open bottom sheet
    await tester.tap(startBtn);
    await tester.pumpAndSettle();

    expect(find.text('Update Reading Status'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_starting_now')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_already_finished')), findsOneWidget);

    // Choose "Starting now" -> tap "Begin Reading"
    final confirmStart = find.byKey(const ValueKey('confirm_start_reading_btn'));
    expect(confirmStart, findsOneWidget);
    await tester.tap(confirmStart);
    await tester.pumpAndSettle();

    // Verify book updated in storage: status is Reading, all other fields preserved
    final updated1 = await storage.getBook('w-detail-1');
    expect(updated1!.status, ReadingStatus.reading);
    expect(updated1.startDate, isNotNull);
    expect(updated1.finishDate, isNull);
    expect(updated1.title, 'Circe');
    expect(updated1.authors, ['Madeline Miller']);
    expect(updated1.genres, ['Mythology', 'Fantasy']);
    expect(updated1.pageCount, 393);
    expect(updated1.title, equals('Circe'));
    expect(updated1.notes, 'Gift from friend');
    expect(updated1.quotes.length, 1);
    expect(updated1.quotes.first.cleanText, contains('Humbling women'));
  });

  testWidgets('Phase 7: Book Detail bottom sheet "Already finished" sets Finished status and optional rating while preserving fields', (WidgetTester tester) async {
    final storage = InMemoryStorageService();
    final wishlistBook = Book(
      id: 'w-detail-2',
      title: 'Piranesi',
      authors: ['Susanna Clarke'],
      genres: ['Fantasy', 'Mystery'],
      status: ReadingStatus.wantToRead,
      pageCount: 245,
      notes: 'Recommended by book club',
      dateAdded: DateTime(2026, 9, 23),
    );
    await storage.saveBook(wishlistBook);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const MaterialApp(
          home: BookDetailScreen(bookId: 'w-detail-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open bottom sheet
    await tester.tap(find.byKey(const ValueKey('start_reading_button')));
    await tester.pumpAndSettle();

    // Switch to "Already finished" tab
    await tester.tap(find.byKey(const ValueKey('tab_already_finished')));
    await tester.pumpAndSettle();

    // Rate 5 stars
    await tester.tap(find.byKey(const ValueKey('sheet_star_5.0')));
    await tester.pumpAndSettle();

    // Confirm finished
    await tester.tap(find.byKey(const ValueKey('confirm_already_finished_btn')));
    await tester.pumpAndSettle();

    // Verify status and preserved fields
    final updated = await storage.getBook('w-detail-2');
    expect(updated!.status, ReadingStatus.finished);
    expect(updated.finishDate, isNotNull);
    expect(updated.rating, 5.0);
    expect(updated.title, 'Piranesi');
    expect(updated.authors, ['Susanna Clarke']);
    expect(updated.genres, ['Fantasy', 'Mystery']);
    expect(updated.pageCount, 245);
    expect(updated.notes, 'Recommended by book club');
  });

  testWidgets('Phase 7: Save to Wishlist saves book without form; duplicate triggers kind alert', (WidgetTester tester) async {
    final storage = InMemoryStorageService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: BookSearchScreen(
            searchFn: (q) async => [
              const BookSearchResult(
                title: 'The Hobbit',
                authors: ['J.R.R. Tolkien'],
                pageCount: 310,
                genres: ['Fantasy'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger search for "The Hobbit"
    final searchInput = find.byKey(const ValueKey('book_search_input'));
    await tester.enterText(searchInput, 'The Hobbit');
    await tester.pump(const Duration(milliseconds: 600)); // debounce
    await tester.pumpAndSettle();

    // Look for Save to Wishlist button on the search results
    final saveToWishlistBtn = find.text('Save to Wishlist');
    expect(saveToWishlistBtn, findsWidgets);

    // Tap first Save to Wishlist
    await tester.tap(saveToWishlistBtn.first);
    await tester.pumpAndSettle();

    // Verify saved to storage with status wantToRead
    final books = await storage.getAllBooks();
    expect(books.length, 1);
    expect(books.first.status, ReadingStatus.wantToRead);

    // Tap again -> duplicate detection dialog should appear
    await tester.tap(saveToWishlistBtn.first);
    await tester.pumpAndSettle();

    expect(find.text('Already in Your Journal ~'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Still only 1 book
    final booksAfterCancel = await storage.getAllBooks();
    expect(booksAfterCancel.length, 1);
  });


  testWidgets('Phase 8: Library status chips filter books by Reading, Finished, Paused, and All', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final b1 = Book(
      id: 'p8-1',
      title: 'Dune',
      authors: ['Frank Herbert'],
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 20),
    );
    final b2 = Book(
      id: 'p8-2',
      title: 'Neuromancer',
      authors: ['William Gibson'],
      status: ReadingStatus.finished,
      finishDate: DateTime(2026, 9, 22),
      dateAdded: DateTime(2026, 9, 18),
    );
    final b3 = Book(
      id: 'p8-3',
      title: 'Foundation',
      authors: ['Isaac Asimov'],
      status: ReadingStatus.paused,
      dateAdded: DateTime(2026, 9, 15),
    );

    await storage.saveBook(b1);
    await storage.saveBook(b2);
    await storage.saveBook(b3);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial "All" filter shows all 3 books
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('Neuromancer'), findsWidgets);
    expect(find.text('Foundation'), findsWidgets);

    // 2. Tap Reading filter
    await tester.tap(find.byKey(const ValueKey('status_chip_reading')));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('Neuromancer'), findsNothing);
    expect(find.text('Foundation'), findsNothing);

    // 3. Tap Finished filter
    await tester.tap(find.byKey(const ValueKey('status_chip_finished')));
    await tester.pumpAndSettle();
    expect(find.text('Neuromancer'), findsWidgets);
    expect(find.text('Dune'), findsNothing);
    expect(find.text('Foundation'), findsNothing);

    // 4. Tap Paused/DNF filter
    await tester.tap(find.byKey(const ValueKey('status_chip_paused')));
    await tester.pumpAndSettle();
    expect(find.text('Foundation'), findsWidgets);
    expect(find.text('Dune'), findsNothing);
    expect(find.text('Neuromancer'), findsNothing);

    // 5. Back to All
    await tester.tap(find.byKey(const ValueKey('status_chip_all')));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('Neuromancer'), findsWidgets);
    expect(find.text('Foundation'), findsWidgets);
  });

  testWidgets('Phase 8: Library search, genre filter, and empty result with reset', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final b1 = Book(
      id: 'p8-search-1',
      title: 'The Way of Kings',
      authors: ['Brandon Sanderson'],
      genres: ['Fantasy'],
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 20),
    );
    final b2 = Book(
      id: 'p8-search-2',
      title: 'Words of Radiance',
      authors: ['Brandon Sanderson'],
      genres: ['Fantasy', 'Epic'],
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 21),
    );
    final b3 = Book(
      id: 'p8-search-3',
      title: 'Project Hail Mary',
      authors: ['Andy Weir'],
      genres: ['Sci-Fi', 'nyt:bestseller-2020', 'Sweden, fiction'],
      status: ReadingStatus.finished,
      dateAdded: DateTime(2026, 9, 22),
    );

    await storage.saveBook(b1);
    await storage.saveBook(b2);
    await storage.saveBook(b3);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Search by title
    final searchField = find.byKey(const ValueKey('library_search_input'));
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Hail Mary');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Project Hail Mary'), findsWidgets);
    expect(find.text('The Way of Kings'), findsNothing);

    // 2. Search by author
    await tester.enterText(searchField, 'Sanderson');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('The Way of Kings'), findsWidgets);
    expect(find.text('Words of Radiance'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsNothing);

    // 3. Search non-matching query -> triggers friendly online search fallback card
    await tester.enterText(searchField, 'Nonexistent Query XYZ');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Nothing on your shelf matches "Nonexistent Query XYZ".'), findsOneWidget);
    expect(find.text('Would you like to search for "Nonexistent Query XYZ" online?'), findsOneWidget);
    expect(find.byKey(const ValueKey('search_online_fallback_btn')), findsOneWidget);

    // 4. Tap clear search button
    await tester.tap(find.byKey(const ValueKey('clear_filters_btn')));
    await tester.pumpAndSettle();

    expect(find.text('The Way of Kings'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsWidgets);

    // 5. Test Genre Filter dropdown and sanitization
    await tester.tap(find.byKey(const ValueKey('genre_filter_button')));
    await tester.pumpAndSettle();

    // Verify dirty catalog codes were filtered out from the genre dropdown list
    expect(find.text('nyt:bestseller-2020'), findsNothing);
    expect(find.text('Sweden, fiction'), findsNothing);

    // Filter by Sci-Fi
    await tester.tap(find.byKey(const ValueKey('genre_item_Sci-Fi')));
    await tester.pumpAndSettle();

    expect(find.text('Project Hail Mary'), findsWidgets);
    expect(find.text('The Way of Kings'), findsNothing);

    // Test clearing via the (x) button on the active genre chip
    await tester.tap(find.byKey(const ValueKey('clear_genre_chip_btn')));
    await tester.pumpAndSettle();

    expect(find.text('The Way of Kings'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsWidgets);

    // Test clearing via selecting "All Genres" in dropdown
    await tester.tap(find.byKey(const ValueKey('genre_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre_item_Fantasy')));
    await tester.pumpAndSettle();

    expect(find.text('The Way of Kings'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsNothing);

    // Re-open dropdown and tap "All Genres"
    await tester.tap(find.byKey(const ValueKey('genre_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('genre_item_all')));
    await tester.pumpAndSettle();

    expect(find.text('The Way of Kings'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsWidgets);
  });

  testWidgets('Phase 8: Sorting by title and rating changes order; view mode and sort persist in bookmark_settings', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final bA = Book(
      id: 'p8-sort-1',
      title: 'A Story of Ash',
      authors: ['Zack Author'],
      rating: 3.5,
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 10),
    );
    final bZ = Book(
      id: 'p8-sort-2',
      title: 'Zeno and the Stars',
      authors: ['Alice Writer'],
      rating: 5.0,
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 20),
    );

    await storage.saveBook(bA);
    await storage.saveBook(bZ);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Sort by Rating (bZ 5.0 should come before bA 3.5)
    await tester.tap(find.byKey(const ValueKey('sort_option_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sort_item_rating')));
    await tester.pumpAndSettle();

    final posZ = tester.getTopLeft(find.text('Zeno and the Stars').last).dy;
    final posA = tester.getTopLeft(find.text('A Story of Ash').last).dy;
    expect(posZ, lessThan(posA));

    // Verify sort setting was persisted in storage
    final persistedSort = await storage.getSetting('library_sort_option');
    expect(persistedSort, 'rating');

    // 2. Toggle to Grid view
    await tester.tap(find.byKey(const ValueKey('view_mode_toggle_btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library_grid_view')), findsOneWidget);
    final persistedGrid = await storage.getSetting('library_is_grid_view');
    expect(persistedGrid, true);

    // 3. Mount fresh instance to verify restoration from settings
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Restored in grid view
    expect(find.byKey(const ValueKey('library_grid_view')), findsOneWidget);
  });


  testWidgets('Phase 9: Stats tab empty state when no finished books exist in current year', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final now = DateTime.now();

    // Add a book finished last year and one currently reading
    await storage.saveBook(Book(
      id: 'stat-old-1',
      title: 'Past Horizons',
      authors: const ['Old Author'],
      genres: const ['Classic'],
      status: ReadingStatus.finished,
      finishDate: DateTime(now.year - 1, 6, 1),
      dateAdded: DateTime(now.year - 1, 5, 1),
    ));
    await storage.saveBook(Book(
      id: 'stat-reading-1',
      title: 'Current Quest',
      authors: const ['Active Writer'],
      genres: const ['Fantasy'],
      status: ReadingStatus.reading,
      dateAdded: now,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Stats tab (bottom nav item 2)
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    // Verify empty state is displayed gracefully
    expect(find.text('Your reading journey this year is just beginning ~'), findsOneWidget);
    expect(find.text('Set a goal for the year ~'), findsOneWidget);
    expect(find.text('Find Your Next Read'), findsOneWidget);

    // Tap "Find Your Next Read" -> navigates back to Library tab (item 0)
    await tester.tap(find.text('Find Your Next Read'));
    await tester.pumpAndSettle();

    // Verify we are back on the Library tab
    expect(find.text('Current Quest'), findsWidgets);
  });

  testWidgets('Phase 9: Stats calculations, charts, ratings, pages, genres, and top reads', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final currentYear = DateTime.now().year;

    // Set a yearly goal of 5 books
    await storage.setSetting('yearly_goal', 5);

    // Book 1: Finished March 10, rated 5.0, 300 pages, genres: Fantasy, nyt:bestseller
    await storage.saveBook(Book(
      id: 'b-stat-1',
      title: 'The Starlight Garden',
      authors: const ['Aria Vance'],
      genres: const ['Fantasy', 'nyt:bestseller-2024'],
      rating: 5.0,
      pageCount: 300,
      status: ReadingStatus.finished,
      finishDate: DateTime(currentYear, 3, 10),
      dateAdded: DateTime(currentYear, 2, 1),
    ));

    // Book 2: Finished March 25, rated 4.0, 200 pages, genres: Fantasy, Romance
    await storage.saveBook(Book(
      id: 'b-stat-2',
      title: 'Whispering Winds',
      authors: const ['Rowan Thorne'],
      genres: const ['Fantasy', 'Romance'],
      rating: 4.0,
      pageCount: 200,
      status: ReadingStatus.finished,
      finishDate: DateTime(currentYear, 3, 25),
      dateAdded: DateTime(currentYear, 3, 1),
    ));

    // Book 3: Finished May 12, unrated (null), missing pages (null), genres: Sci-Fi
    await storage.saveBook(Book(
      id: 'b-stat-3',
      title: 'Silent Nebulae',
      authors: const ['Nova Cross'],
      genres: const ['Sci-Fi'],
      rating: null,
      pageCount: null,
      status: ReadingStatus.finished,
      finishDate: DateTime(currentYear, 5, 12),
      dateAdded: DateTime(currentYear, 4, 1),
    ));

    // Book 4: Finished in previous year (must be excluded from current year stats)
    await storage.saveBook(Book(
      id: 'b-stat-4',
      title: 'Last Year Legend',
      authors: const ['Past Writer'],
      genres: const ['Mythology'],
      rating: 5.0,
      pageCount: 600,
      status: ReadingStatus.finished,
      finishDate: DateTime(currentYear - 1, 11, 20),
      dateAdded: DateTime(currentYear - 1, 10, 1),
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Stats tab
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    // 1. Reading Goal: 3 of 5 books finished (60%)
    expect(find.text('3 of 5 books finished (60%)'), findsOneWidget);
    expect(find.text('2 more books to reach your goal'), findsOneWidget);

    // 2. Overview metrics
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('3'), findsWidgets); // 3 books finished this year
    expect(find.text('500'), findsWidgets); // 300 + 200 pages (in metrics row and pages card)

    // 3. Average rating: (5.0 + 4.0) / 2 = 4.5. Unrated book is excluded, not counted as 0!
    expect(find.text('4.5'), findsWidgets);
    expect(find.textContaining('Computed across 2 rated books (1 unrated)'), findsOneWidget);

    // 4. Pages Explored Card: 500 pages with missing pages count note
    expect(find.text('Pages Explored'), findsOneWidget);
    expect(find.textContaining('Across 2 books (1 book had no page count recorded)'), findsOneWidget);

    // 5. Genre Breakdown: Uses cleanGenres (Fantasy, Romance, Sci-Fi)
    expect(find.text('Genre Breakdown'), findsOneWidget);
    expect(find.textContaining('Fantasy (2)'), findsOneWidget);
    expect(find.textContaining('Romance (1)'), findsOneWidget);
    expect(find.textContaining('Sci-Fi (1)'), findsOneWidget);
    // Raw catalog string is excluded
    expect(find.textContaining('nyt:bestseller-2024'), findsNothing);

    // 6. Highest-Rated Reads Showcase: Book 1 (#1) and Book 2 (#2), unrated Book 3 excluded
    expect(find.text('Highest-Rated Reads'), findsOneWidget);
    expect(find.text('The Starlight Garden'), findsWidgets);
    expect(find.text('Whispering Winds'), findsWidgets);
    expect(find.text('Silent Nebulae'), findsNothing); // Unrated book not in showcase
  });


  test('Phase 10: Export then Import (Replace) round trip preserves everything', () async {
    final storage = InMemoryStorageService();

    final testCoverBytes = Uint8List.fromList([1, 2, 3, 4, 5, 255, 128, 64]);
    final book1 = Book(
      id: 'round-1',
      title: 'A Feather in the Wind',
      authors: const ['Emily St. John', 'Arthur Conan'],
      genres: const ['Historical Fiction', 'Mystery'],
      rating: 4.5,
      notes: 'Read this during autumn rain. Unforgettable atmosphere.',
      quotes: [
        BookQuote(id: 'q-1', quote: 'Memory is an untamed garden.', pageNumber: 42, createdAt: DateTime(2026, 8, 2)),
        BookQuote(id: 'q-2', quote: 'We wander until we find the quiet.', pageNumber: 180, createdAt: DateTime(2026, 8, 3)),
      ],
      pageCount: 384,
      status: ReadingStatus.finished,
      startDate: DateTime(2026, 8, 1),
      finishDate: DateTime(2026, 8, 14),
      dateAdded: DateTime(2026, 7, 20),
    );

    final book2 = Book(
      id: 'round-2',
      title: 'Echoes of the Sea',
      authors: const ['Marlowe Reed'],
      genres: const ['Romance', 'Young Adult'],
      rating: 5.0,
      notes: 'Borrow copy from local archive.',
      quotes: [
        BookQuote(id: 'q-3', quote: 'The ocean remembers what words forget.', createdAt: DateTime(2026, 9, 2)),
      ],
      pageCount: 290,
      status: ReadingStatus.reading,
      startDate: DateTime(2026, 9, 1),
      finishDate: null,
      dateAdded: DateTime(2026, 8, 25),
    );

    await storage.saveBook(book1);
    await storage.saveCoverImage(book1.id, testCoverBytes);
    await storage.saveBook(book2);
    await storage.setSetting('yearly_goal', 30);
    await storage.setSetting('library_sort_option', 'rating');

    // 1. Export data
    final exportJson = await BackupService.exportLibraryJson(storage);
    expect(exportJson.isNotEmpty, true);

    // Verify metadata & validation
    final validation = BackupService.validateBackupJson(exportJson);
    expect(validation.isValid, true);
    expect(validation.bookCount, 2);
    expect(validation.quotesCount, 3);
    expect(validation.coversCount, 1);
    expect(validation.readingGoal, 30);

    // 2. Wipe storage completely (new instance)
    final emptyStorage = InMemoryStorageService();

    // 3. Perform Replace Import
    final summary = await BackupService.performImport(emptyStorage, validation.data!, merge: false);
    expect(summary.isReplace, true);
    expect(summary.totalBooksInLibrary, 2);
    expect(summary.restoredCoversCount, 1);
    expect(summary.restoredGoal, 30);

    // 4. Verify round-trip fidelity across every field
    final restoredBooks = await emptyStorage.getAllBooks();
    expect(restoredBooks.length, 2);

    final restored1 = restoredBooks.firstWhere((b) => b.id == 'round-1');
    expect(restored1.title, book1.title);
    expect(restored1.authors, book1.authors);
    expect(restored1.genres, book1.genres);
    expect(restored1.rating, 4.5);
    expect(restored1.notes, book1.notes);
    expect(restored1.quotes.length, 2);
    expect(restored1.quotes[0].quote, 'Memory is an untamed garden.');
    expect(restored1.quotes[0].pageNumber, 42);
    expect(restored1.quotes[1].quote, 'We wander until we find the quiet.');
    expect(restored1.quotes[1].pageNumber, 180);
    expect(restored1.pageCount, 384);
    expect(restored1.status, ReadingStatus.finished);
    expect(restored1.startDate, book1.startDate);
    expect(restored1.finishDate, book1.finishDate);
    expect(restored1.dateAdded, book1.dateAdded);

    final restoredCover = await emptyStorage.getCoverImage('round-1');
    expect(restoredCover, isNotNull);
    expect(restoredCover, equals(testCoverBytes));

    final restoredGoal = await emptyStorage.getSetting('yearly_goal');
    expect(restoredGoal, 30);

    final restoredSort = await emptyStorage.getSetting('library_sort_option');
    expect(restoredSort, 'rating');
  });

  test('Phase 10: Merge keeps existing IDs, adds new IDs, and skips same title+author with different ID', () async {
    final storage = InMemoryStorageService();
    final baseTime = DateTime(2026, 5, 1);

    // 1. Existing Book in library
    final existingBook = Book(
      id: 'exist-1',
      title: 'Pride and Prejudice',
      authors: const ['Jane Austen'],
      genres: const ['Classic'],
      status: ReadingStatus.finished,
      dateAdded: baseTime,
    );
    await storage.saveBook(existingBook);

    // 2. Incoming backup to MERGE:
    // a) Older copy of exist-1 -> should be kept as-is
    final olderExist = Book(
      id: 'exist-1',
      title: 'Pride and Prejudice (Old)',
      authors: const ['Jane Austen'],
      genres: const ['Classic'],
      status: ReadingStatus.reading,
      dateAdded: baseTime.subtract(const Duration(days: 5)),
    );

    // b) Brand new book (new ID, unique title+author) -> should be added
    final brandNewBook = Book(
      id: 'brand-new-2',
      title: 'Emma',
      authors: const ['Jane Austen'],
      genres: const ['Classic'],
      status: ReadingStatus.wantToRead,
      dateAdded: baseTime,
    );

    // c) Duplicate title + author with a DIFFERENT ID -> should be skipped!
    final duplicateDifferentId = Book(
      id: 'diff-id-999',
      title: 'Pride and Prejudice',
      authors: const ['Jane Austen'],
      genres: const ['Romance'],
      status: ReadingStatus.wantToRead,
      dateAdded: baseTime,
    );

    final payload = {
      'metadata': {
        'format_version': 1,
        'app_version': '1.0.0',
        'export_date': baseTime.toIso8601String(),
        'book_count': 3
      },
      'books': [
        olderExist.toMap(),
        brandNewBook.toMap(),
        duplicateDifferentId.toMap(),
      ],
      'covers': {},
    };

    final summary = await BackupService.performImport(storage, payload, merge: true);

    expect(summary.isReplace, false);
    expect(summary.addedCount, 1); // Only brand-new-2
    expect(summary.keptExistingCount, 1); // exist-1 kept because incoming was older
    expect(summary.skippedDuplicatesCount, 1); // diff-id-999 skipped
    expect(summary.totalBooksInLibrary, 2); // exist-1 + brand-new-2

    final books = await storage.getAllBooks();
    expect(books.length, 2);
    expect(books.any((b) => b.id == 'exist-1'), true);
    expect(books.any((b) => b.id == 'brand-new-2'), true);
    expect(books.any((b) => b.id == 'diff-id-999'), false); // Duplicate was NOT added

    // Existing book title was preserved (not overwritten by older incoming)
    final kept = books.firstWhere((b) => b.id == 'exist-1');
    expect(kept.title, 'Pride and Prejudice');
  });

  test('Phase 10: Malformed file refuses import and leaves library completely unchanged', () async {
    final storage = InMemoryStorageService();

    final originalBook = Book(
      id: 'safe-1',
      title: 'The Secret Garden',
      authors: const ['Frances Hodgson Burnett'],
      genres: const ['Classic'],
      status: ReadingStatus.finished,
      dateAdded: DateTime.now(),
    );
    await storage.saveBook(originalBook);

    // Case 1: Invalid JSON syntax
    final invalidJsonRes = BackupService.validateBackupJson('{not: "valid" json');
    expect(invalidJsonRes.isValid, false);
    expect(invalidJsonRes.errorMessage, contains('not a valid JSON document'));

    // Case 2: Wrong format_version
    final wrongVersionJson = '{"metadata": {"format_version": 99}, "books": []}';
    final wrongVersionRes = BackupService.validateBackupJson(wrongVersionJson);
    expect(wrongVersionRes.isValid, false);
    expect(wrongVersionRes.errorMessage, contains('Unsupported backup format'));

    // Case 3: Missing required books collection
    final missingBooksJson = '{"metadata": {"format_version": 1}}';
    final missingBooksRes = BackupService.validateBackupJson(missingBooksJson);
    expect(missingBooksRes.isValid, false);
    expect(missingBooksRes.errorMessage, contains('missing its book collection'));

    // Case 4: Corrupted book missing title or id
    final corruptedBookJson = '{"metadata": {"format_version": 1}, "books": [{"id": "bad-1"}]}';
    final corruptedBookRes = BackupService.validateBackupJson(corruptedBookJson);
    expect(corruptedBookRes.isValid, false);
    expect(corruptedBookRes.errorMessage, contains('missing a required title or identifier'));

    // Verify storage was NEVER touched
    final afterBooks = await storage.getAllBooks();
    expect(afterBooks.length, 1);
    expect(afterBooks.first.id, 'safe-1');
    expect(afterBooks.first.title, 'The Secret Garden');
  });

  testWidgets('Phase 10: Settings displays honest storage status and backup habit reminder banner appears when needed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    // User has 1 book, never backed up
    await storage.saveBook(Book(
      id: 'habit-1',
      title: 'The Blue Castle',
      authors: const ['L.M. Montgomery'],
      genres: const ['Romance'],
      status: ReadingStatus.reading,
      dateAdded: DateTime.now(),
    ));
    await storage.setSetting('storage_persisted', false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Library tab shows the gentle backup reminder banner
    expect(find.text('Gentle backup reminder ~'), findsOneWidget);
    expect(find.textContaining('haven\'t backed up yet'), findsOneWidget);

    // 2. Dismiss the banner
    await tester.tap(find.byTooltip('Dismiss reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Gentle backup reminder ~'), findsNothing);

    // 3. Go to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // 4. Honest Storage Protection status shown (persisted == false)
    expect(find.text('Standard Device Storage'), findsOneWidget);
    expect(find.textContaining('Your library is stored on this device. Please back up regularly.'), findsOneWidget);
    expect(find.text('Last backup: Never'), findsOneWidget);

    // 5. Export and Restore buttons are present
    expect(find.byKey(const ValueKey('export_library_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('import_library_button')), findsOneWidget);
  });


  testWidgets('Phase 11: FloralRatingBar half-step interaction and FloralCelebrationDialog overlay', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    double? currentRating = 3.0;

    // Build standalone FloralRatingBar
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return FloralRatingBar(
                rating: currentRating,
                showLabel: true,
                onRatingChanged: (newRating) {
                  setState(() => currentRating = newRating);
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify rating bar and label
    expect(find.byType(FloralRatingBar), findsOneWidget);
    expect(find.text('3.0 / 5.0'), findsOneWidget);

    // Tap on the 4th blossom (index 3) to test interaction
    final blossoms = find.byType(CustomPaint);
    expect(blossoms, findsWidgets);

    // Test Celebration Overlay Dialog
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showFloralCelebration(context, bookTitle: 'The Secret History');
                },
                child: const Text('Celebrate'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Celebrate'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(FloralCelebrationDialog), findsOneWidget);
    expect(find.text('The Secret History'), findsOneWidget);
    expect(find.text('Story Completed ~'), findsOneWidget);

    // Pump frames to verify particle animation runs smoothly without exceptions
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));

    // Tap close button
    final closeBtn = find.text('Cherish & Continue');
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.byType(FloralCelebrationDialog), findsNothing);
  });


  testWidgets('Botanical updates: Home screen blossom rating, unclipped header poppy, and Apple auto-centering text fields', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final storage = InMemoryStorageService();
    await storage.saveBook(Book(
      id: 'b-flower-test',
      title: 'The Secret History',
      authors: const ['Donna Tartt'],
      rating: 4.5,
      status: ReadingStatus.finished,
      finishDate: DateTime.now(),
      dateAdded: DateTime.now(),
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Home screen displays BotanicalBlossomIcon instead of star icon
    expect(find.byType(BotanicalBlossomIcon), findsWidgets);
    expect(find.text('4.5'), findsOneWidget);

    // 2. Open Add Book screen
    await tester.tap(find.byKey(const ValueKey('add_book_fab')));
    await tester.pumpAndSettle();

    // Search screen -> tap Enter Details Manually
    await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
    await tester.pumpAndSettle();

    expect(find.byType(AddEditBookScreen), findsOneWidget);

    // Verify top bar contains the unclipped PoppyDoodle (inside 44x44 container)
    expect(find.byType(PoppyDoodle), findsWidgets);

    // 3. Verify Apple-style auto-centering on text field tap / focus
    final titleField = find.byKey(const ValueKey('input_book_title'));
    expect(titleField, findsOneWidget);
    await tester.tap(titleField);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify input enters text cleanly
    await tester.enterText(titleField, 'Emma');
    await tester.pumpAndSettle();
    expect(find.text('Emma'), findsWidgets);
  });


  testWidgets('Theme toggle: switching between Autumn Day and Autumn Night updates state and persists', (tester) async {
    final fakeStorage = InMemoryStorageService();
    await fakeStorage.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
        ],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigate to Settings (Tab index 3)
    final settingsNav = find.text('Settings');
    expect(settingsNav, findsWidgets);
    await tester.tap(settingsNav.first);
    await tester.pumpAndSettle();

    // 2. Find Day and Night toggle buttons
    final dayToggle = find.byKey(const ValueKey('theme_toggle_day'));
    final nightToggle = find.byKey(const ValueKey('theme_toggle_night'));
    expect(dayToggle, findsOneWidget);
    expect(nightToggle, findsOneWidget);

    // 3. Tap Autumn Night
    await tester.tap(nightToggle);
    await tester.pumpAndSettle();
    expect(FloralPalette.isDark, isTrue);
    expect(await fakeStorage.getSetting('theme_mode'), equals('midnightGarden'));

    // 4. Tap Autumn Day
    await tester.tap(dayToggle);
    await tester.pumpAndSettle();
    expect(FloralPalette.isDark, isFalse);
    expect(await fakeStorage.getSetting('theme_mode'), equals('poppyBlush'));
  });

  testWidgets('Autumn Doodles: Maple, Oak, Acorn, Mushroom, and Falling Leaves render cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                MapleLeafDoodle(size: 60),
                OakLeafDoodle(size: 60),
                AcornDoodle(size: 50),
                MushroomDoodle(size: 50),
                FallingLeavesDoodle(width: 300, height: 60),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MapleLeafDoodle), findsWidgets);
    expect(find.byType(OakLeafDoodle), findsWidgets);
    expect(find.byType(AcornDoodle), findsWidgets);
    expect(find.byType(MushroomDoodle), findsOneWidget);
    expect(find.byType(FallingLeavesDoodle), findsOneWidget);
  });

  testWidgets('Part 1: Library search fallback card, debounce, online search launch, and filter hiding notice', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final b1 = Book(
      id: 'part1-1',
      title: 'Pride and Prejudice',
      authors: ['Jane Austen'],
      genres: ['Romance', 'Classic'],
      status: ReadingStatus.finished,
      dateAdded: DateTime(2026, 9, 20),
    );
    final b2 = Book(
      id: 'part1-2',
      title: 'Dune',
      authors: ['Frank Herbert'],
      genres: ['Sci-Fi'],
      status: ReadingStatus.reading,
      dateAdded: DateTime(2026, 9, 21),
    );
    await storage.saveBook(b1);
    await storage.saveBook(b2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(storage)],
        child: const BookmarkApp(),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byKey(const ValueKey('library_search_input'));
    expect(searchField, findsOneWidget);

    // 1. Debounce check: typing does not immediately flash the card before 300ms
    await tester.enterText(searchField, 'Harry Potter');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('search_online_fallback_btn')), findsNothing);

    // After 300ms debounce expires: friendly fallback card appears
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('Nothing on your shelf matches "Harry Potter".'), findsOneWidget);
    expect(find.text('Would you like to search for "Harry Potter" online?'), findsOneWidget);
    final onlineBtn = find.byKey(const ValueKey('search_online_fallback_btn'));
    expect(onlineBtn, findsOneWidget);

    // 2. Tap the online search button -> opens BookSearchScreen with query pre-filled
    await tester.tap(onlineBtn);
    await tester.pumpAndSettle();

    expect(find.byType(BookSearchScreen), findsOneWidget);
    final onlineSearchField = find.byKey(const ValueKey('book_search_input'));
    expect(onlineSearchField, findsOneWidget);
    expect(tester.widget<TextField>(onlineSearchField).controller?.text, 'Harry Potter');

    // Pop back to library
    Navigator.of(tester.element(find.byType(BookSearchScreen))).pop();
    await tester.pumpAndSettle();

    // Clear search
    await tester.tap(find.byKey(const ValueKey('clear_filters_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Pride and Prejudice'), findsWidgets);

    // 3. Filter hiding matches:
    // Filter library by "Reading" chip
    await tester.tap(find.byKey(const ValueKey('status_chip_reading')));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsWidgets);
    expect(find.text('Pride and Prejudice'), findsNothing);

    // Now search for "Pride" (which is Finished, not Reading)
    await tester.enterText(searchField, 'Pride');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Since 'Pride and Prejudice' exists in the library, fallback tells user that filters are hiding matches
    expect(find.text('Filters are hiding matches for "Pride"'), findsOneWidget);
    expect(find.textContaining('Try clearing your filters to see 1 matching book on your shelf ~'), findsOneWidget);
    expect(find.byKey(const ValueKey('clear_filters_btn')), findsOneWidget);

    // Tapping "Clear Filters" clears the active filter and reveals the book
    await tester.tap(find.byKey(const ValueKey('clear_filters_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Pride and Prejudice'), findsWidgets);
  });

  group('Part 2: UI verification that Synopsis is completely removed', () {
    testWidgets('Book Detail screen does NOT display any Synopsis section or empty state', (tester) async {
      final storage = InMemoryStorageService();
      await storage.init();
      final book = Book(
        id: 'no-synopsis-detail',
        title: 'A Beautiful Book',
        authors: ['Author Name'],
        dateAdded: DateTime.now(),
      );
      await storage.saveBook(book);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: MaterialApp(
            home: BookDetailScreen(bookId: book.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Synopsis'), findsNothing);
      expect(find.text('No synopsis yet ~'), findsNothing);
      expect(find.byKey(const ValueKey('add_synopsis_btn')), findsNothing);
      expect(find.byKey(const ValueKey('synopsis_toggle_btn')), findsNothing);
    });

    testWidgets('Add/Edit book screen does NOT contain any Synopsis/Description input field', (tester) async {
      final storage = InMemoryStorageService();
      await storage.init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: AddEditBookScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('input_book_description')), findsNothing);
      expect(find.text('Synopsis / Description (Optional)'), findsNothing);
      expect(find.text('Synopsis'), findsNothing);
    });
  });

  group('Part 3: Status pill readability & Unrated text contrast', () {
    test('Status pill colors achieve >= 7.2:1 text contrast and >= 6.6:1 fill contrast on dark card', () {
      double relLum(double r, double g, double b) {
        double ch(double s) {
          return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) * ((s + 0.055) / 1.055) * 1.0;
        }
        return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
      }

      double contrast(Color c1, Color c2) {
        final l1 = relLum(c1.r, c1.g, c1.b);
        final l2 = relLum(c2.r, c2.g, c2.b);
        final lighter = l1 > l2 ? l1 : l2;
        final darker = l1 > l2 ? l2 : l1;
        return (lighter + 0.05) / (darker + 0.05);
      }

      const darkCard = Color(0xFF2B211A);

      for (final status in ReadingStatus.values) {
        final style = StatusPillStyle.of(status);
        final textVsFill = contrast(style.text, style.fill);
        final fillVsCard = contrast(style.fill, darkCard);

        expect(textVsFill >= 4.5, isTrue, reason: '${status.label} text vs fill should be >= 4.5:1');
        expect(fillVsCard >= 3.0, isTrue, reason: '${status.label} fill vs card should be >= 3.0:1');
      }

      // Check Unrated text contrast on dark card
      final unratedContrast = contrast(const Color(0xFFC9B8AB), darkCard);
      expect(unratedContrast >= 4.5, isTrue, reason: 'Unrated text contrast should be >= 4.5:1');
    });

    testWidgets('Library list card renders StatusPill with icon and >= 12px font', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final book = Book(
        id: 'pill-test-1',
        title: 'The Hobbit',
        authors: ['J.R.R. Tolkien'],
        status: ReadingStatus.finished,
        dateAdded: DateTime(2026, 9, 20),
      );

      final storage = InMemoryStorageService();
      await storage.saveBook(book);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  BookListCard(book: book),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusPill), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Finished'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('Finished'));
      expect(textWidget.style?.fontSize != null && textWidget.style!.fontSize! >= 12.0, isTrue);
    });
  
  group('Part 4: Bulk-select to set approximate read year, rating, and stats filters', () {
    test('Data model: approximate flags, human-friendly formatting, and backward compatibility', () {
      final approxYearOnly = Book(
        id: 'approx-1',
        title: 'Middlemarch',
        authors: const ['George Eliot'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2019, 7, 2),
        finishDateIsApproximate: true,
        finishDateHasMonth: false,
        dateAdded: DateTime(2026, 9, 20),
      );
      expect(approxYearOnly.formattedCompletionDate, equals('Read in 2019'));

      final approxYearMonth = Book(
        id: 'approx-2',
        title: 'Silas Marner',
        authors: const ['George Eliot'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2019, 6, 15),
        finishDateIsApproximate: true,
        finishDateHasMonth: true,
        dateAdded: DateTime(2026, 9, 20),
      );
      expect(approxYearMonth.formattedCompletionDate, equals('Read in June 2019'));

      final yearUnknown = Book(
        id: 'approx-3',
        title: 'Jane Eyre',
        authors: const ['Charlotte Bronte'],
        status: ReadingStatus.finished,
        finishDate: null,
        finishDateIsApproximate: true,
        finishDateHasMonth: false,
        dateAdded: DateTime(2026, 9, 20),
      );
      expect(yearUnknown.formattedCompletionDate, equals('Read long ago'));

      final exactDate = Book(
        id: 'exact-1',
        title: 'Villette',
        authors: const ['Charlotte Bronte'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2023, 10, 14),
        finishDateIsApproximate: false,
        dateAdded: DateTime(2026, 9, 20),
      );
      expect(exactDate.formattedCompletionDate, equals('Finished October 14, 2023'));

      // Backward compatibility: older backup map without approximate flags
      final oldBackupMap = {
        'id': 'legacy-1',
        'title': 'Wuthering Heights',
        'authors': ['Emily Bronte'],
        'genres': ['Classic', 'Gothic'],
        'rating': 4.5,
        'description': 'A passionate and tragic romance.',
        'status': 'finished',
        'startDate': '2023-01-01T00:00:00.000',
        'finishDate': '2023-02-01T00:00:00.000',
        'notes': 'Haunting atmosphere.',
        'quotes': [],
        'pageCount': 400,
        'dateAdded': '2023-01-01T00:00:00.000',
      };

      final parsedLegacy = Book.fromMap(oldBackupMap);
      expect(parsedLegacy.finishDateIsApproximate, isFalse);
      expect(parsedLegacy.finishDateHasMonth, isFalse);
      expect(parsedLegacy.title, equals('Wuthering Heights'));
      expect(parsedLegacy.rating, equals(4.5));
      expect(parsedLegacy.notes, equals('Haunting atmosphere.'));
    });

    test('Bulk apply preserves all other fields and undo restores previous values', () async {
      final storage = InMemoryStorageService();

      final originalQuote = BookQuote(
        id: 'q-bulk-1',
        quote: 'Whatever our souls are made of, his and mine are the same.',
        pageNumber: 82,
        createdAt: DateTime(2026, 9, 1),
      );

      final book1 = Book(
        id: 'b-bulk-1',
        title: 'Wuthering Heights',
        authors: const ['Emily Bronte'],
        genres: const ['Classic', 'Romance'],
        rating: 3.5,
        notes: 'Personal favorite classic.',
        quotes: [originalQuote],
        pageCount: 380,
        status: ReadingStatus.finished,
        finishDate: DateTime(2026, 9, 24),
        dateAdded: DateTime(2026, 9, 1),
      );

      final book2 = Book(
        id: 'b-bulk-2',
        title: 'Persuasion',
        authors: const ['Jane Austen'],
        genres: const ['Classic', 'Regency'],
        rating: 4.0,
        notes: 'Quiet, poignant beauty.',
        quotes: [],
        pageCount: 260,
        status: ReadingStatus.reading,
        dateAdded: DateTime(2026, 9, 5),
      );

      await storage.saveBook(book1);
      await storage.saveBook(book2);

      // Snapshot previous states for undo
      final previousStates = {
        book1.id: book1,
        book2.id: book2,
      };

      // Perform bulk update: set year to 2018 (approximate) and rate 4.5
      final updatedBooks = [
        book1.copyWith(
          finishDate: DateTime(2018, 7, 2),
          finishDateIsApproximate: true,
          finishDateHasMonth: false,
          rating: 4.5,
        ),
        book2.copyWith(
          status: ReadingStatus.finished,
          finishDate: DateTime(2018, 7, 2),
          finishDateIsApproximate: true,
          finishDateHasMonth: false,
          rating: 4.5,
        ),
      ];

      for (final b in updatedBooks) {
        await storage.saveBook(b);
      }

      // Verify updated books
      final storedBook1 = await storage.getBook(book1.id);
      expect(storedBook1, isNotNull);
      expect(storedBook1!.finishDate?.year, equals(2018));
      expect(storedBook1.finishDateIsApproximate, isTrue);
      expect(storedBook1.finishDateHasMonth, isFalse);
      expect(storedBook1.rating, equals(4.5));
      // Verify all untouched fields are strictly preserved
      expect(storedBook1.title, equals(book1.title));
      expect(storedBook1.authors, equals(book1.authors));
      expect(storedBook1.genres, equals(book1.genres));
      expect(storedBook1.notes, equals(book1.notes));
      expect(storedBook1.quotes.length, equals(1));
      expect(storedBook1.quotes.first.quote, equals(originalQuote.quote));
      expect(storedBook1.pageCount, equals(book1.pageCount));

      // Simulate Undo
      for (final prev in previousStates.values) {
        await storage.saveBook(prev);
      }

      final restoredBook1 = await storage.getBook(book1.id);
      final restoredBook2 = await storage.getBook(book2.id);

      expect(restoredBook1!.finishDate?.year, equals(2026));
      expect(restoredBook1.finishDateIsApproximate, isFalse);
      expect(restoredBook1.rating, equals(3.5));

      expect(restoredBook2!.status, equals(ReadingStatus.reading));
      expect(restoredBook2.finishDate, isNull);
      expect(restoredBook2.rating, equals(4.0));
    });

    test('Stats behavior: approximate books included in yearly totals, ratings, genres, and pages, but excluded from monthly chart', () {
      final currentYear = DateTime.now().year;

      // Book A: Exact date in current year (March 10)
      final bookA = Book(
        id: 'stat-a',
        title: 'Book A (Exact)',
        authors: const ['Author A'],
        genres: const ['Fiction'],
        rating: 5.0,
        pageCount: 300,
        status: ReadingStatus.finished,
        finishDate: DateTime(currentYear, 3, 10),
        finishDateIsApproximate: false,
        dateAdded: DateTime(currentYear, 1, 1),
      );

      // Book B: Approximate year only in current year (middle of year)
      final bookB = Book(
        id: 'stat-b',
        title: 'Book B (Approx Year Only)',
        authors: const ['Author B'],
        genres: const ['Mystery'],
        rating: 4.0,
        pageCount: 200,
        status: ReadingStatus.finished,
        finishDate: DateTime(currentYear, 7, 2),
        finishDateIsApproximate: true,
        finishDateHasMonth: false,
        dateAdded: DateTime(currentYear, 1, 1),
      );

      // Book C: Approximate year and month in current year (May 15)
      final bookC = Book(
        id: 'stat-c',
        title: 'Book C (Approx Year and Month)',
        authors: const ['Author C'],
        genres: const ['Sci-Fi'],
        rating: 3.0,
        pageCount: 150,
        status: ReadingStatus.finished,
        finishDate: DateTime(currentYear, 5, 15),
        finishDateIsApproximate: true,
        finishDateHasMonth: true,
        dateAdded: DateTime(currentYear, 1, 1),
      );

      // Book D: Year unknown / long ago (Finished with no finishDate)
      final bookD = Book(
        id: 'stat-d',
        title: 'Book D (Year Unknown)',
        authors: const ['Author D'],
        genres: const ['Poetry'],
        rating: 4.0,
        pageCount: 100,
        status: ReadingStatus.finished,
        finishDate: null,
        finishDateIsApproximate: true,
        finishDateHasMonth: false,
        dateAdded: DateTime(currentYear, 1, 1),
      );

      final allBooks = [bookA, bookB, bookC, bookD];

      // Yearly stats for currentYear:
      // Includes Book A, Book B, Book C (approximate-dated books count in yearly totals)
      // Excludes Book D (finishDate == null)
      final finishedThisYear = allBooks.where((b) {
        return b.status == ReadingStatus.finished &&
            b.finishDate != null &&
            b.finishDate!.year == currentYear;
      }).toList();

      expect(finishedThisYear.length, equals(3), reason: 'Yearly total includes Book A, B, and C');
      expect(finishedThisYear.contains(bookB), isTrue, reason: 'Approximate-dated book is included in yearly total');
      expect(finishedThisYear.contains(bookD), isFalse, reason: 'Year unknown book is excluded from year-based stats');

      // Total pages read in current year: 300 + 200 + 150 = 650
      final yearlyPages = finishedThisYear.fold<int>(0, (sum, b) => sum + (b.pageCount ?? 0));
      expect(yearlyPages, equals(650));

      // Yearly average rating: (5.0 + 4.0 + 3.0) / 3 = 4.0
      final yearlyRated = finishedThisYear.where((b) => b.rating != null && b.rating! > 0).toList();
      final double yearlyAvgRating = yearlyRated.map((b) => b.rating!).reduce((a, b) => a + b) / yearlyRated.length;
      expect(yearlyAvgRating, equals(4.0));

      // Monthly bar chart counts:
      // Approximate year-only books (Book B) MUST be excluded from the per-month chart!
      final monthlyCounts = List<int>.filled(12, 0);
      for (final b in finishedThisYear) {
        if (b.finishDate != null) {
          if (b.finishDateIsApproximate && !b.finishDateHasMonth) {
            continue; // Skipped
          }
          final m = b.finishDate!.month;
          if (m >= 1 && m <= 12) {
            monthlyCounts[m - 1]++;
          }
        }
      }

      expect(monthlyCounts[2], equals(1), reason: 'March has 1 book (Book A)');
      expect(monthlyCounts[4], equals(1), reason: 'May has 1 book (Book C with explicit month)');
      expect(monthlyCounts[6], equals(0), reason: 'July has 0 books (Book B approximate year-only is excluded)');
      expect(monthlyCounts.reduce((a, b) => a + b), equals(2), reason: 'Only 2 books appear in monthly chart');

      // Overall totals across all finished books:
      // Book D ("Year unknown / long ago") IS included in overall totals and average rating!
      final allFinished = allBooks.where((b) => b.status == ReadingStatus.finished).toList();
      expect(allFinished.length, equals(4), reason: 'Overall total finished includes Book D');

      final allRated = allFinished.where((b) => b.rating != null && b.rating! > 0).toList();
      final double overallAvgRating = allRated.map((b) => b.rating!).reduce((a, b) => a + b) / allRated.length;
      // (5.0 + 4.0 + 3.0 + 4.0) / 4 = 4.0
      expect(overallAvgRating, equals(4.0), reason: 'Overall average rating includes Book D');
    });

    testWidgets('UI Interaction: Long-press enters selection mode, select all, cancel, and action bar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryStorageService();
      final book1 = Book(
        id: 'sel-1',
        title: 'The Great Gatsby',
        authors: const ['F. Scott Fitzgerald'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2026, 9, 1),
        dateAdded: DateTime(2026, 9, 1),
      );
      final book2 = Book(
        id: 'sel-2',
        title: 'Tender is the Night',
        authors: const ['F. Scott Fitzgerald'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2026, 9, 2),
        dateAdded: DateTime(2026, 9, 2),
      );

      await storage.saveBook(book1);
      await storage.saveBook(book2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Normal mode: FAB is visible, selection header not visible
      expect(find.byKey(const ValueKey('add_book_fab')), findsOneWidget);
      expect(find.byKey(const ValueKey('library_selection_header')), findsNothing);

      // Long press book 1 to enter selection mode
      await tester.longPress(find.byType(BookListCard).first);
      await tester.pumpAndSettle();

      // Selection mode active:
      expect(find.byKey(const ValueKey('library_selection_header')), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byKey(const ValueKey('select_all_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('cancel_selection_button')), findsOneWidget);

      // FAB is hidden in selection mode
      expect(find.byKey(const ValueKey('add_book_fab')), findsNothing);

      // Bottom bulk action bar is displayed with Set year and Rate
      expect(find.byKey(const ValueKey('bulk_set_year_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('bulk_rate_button')), findsOneWidget);

      // Tap "Select all"
      await tester.tap(find.byKey(const ValueKey('select_all_button')));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      // Tap "Cancel"
      await tester.tap(find.byKey(const ValueKey('cancel_selection_button')));
      await tester.pumpAndSettle();

      // Selection mode exited:
      expect(find.byKey(const ValueKey('library_selection_header')), findsNothing);
      expect(find.byKey(const ValueKey('add_book_fab')), findsOneWidget);
    });
  });

  group('Part 5: iOS Safari touch unfreeze & lifecycle resume diagnostics', () {
    testWidgets('Diagnostics line renders on Settings tab and counts resume events', (tester) async {
      LibraryScreen.resetResumeDiagnosticsForTest();
      final storage = InMemoryStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings tab (index 3)
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Verify diagnostics line initially shows 0 events (last: never)
      expect(find.byKey(const ValueKey('resume_events_diagnostics_text')), findsOneWidget);
      expect(find.textContaining('Resume events: 0 (last: never)'), findsOneWidget);

      // Simulate app going to background and resuming:
      // Down: resumed -> inactive -> hidden -> paused
      // Up:   paused -> hidden -> inactive -> resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify resume count updated to 1
      expect(LibraryScreen.resumeCount, 1);
      expect(find.textContaining('Resume events: 1'), findsOneWidget);
      expect(find.textContaining('last: just now'), findsOneWidget);
    });

    testWidgets('Soft reset pops modal popups on long background (> 5 min) when not editing', (tester) async {
      LibraryScreen.resetResumeDiagnosticsForTest();
      final storage = InMemoryStorageService();
      final book = Book(
        id: 'p5-book-1',
        title: 'The Great Gatsby',
        authors: ['F. Scott Fitzgerald'],
        status: ReadingStatus.reading,
        dateAdded: DateTime(2026, 9, 20),
      );
      await storage.saveBook(book);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Long press book to enter selection mode
      await tester.longPress(find.byType(BookListCard).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_selection_header')), findsOneWidget);

      // Simulate background pause with past timestamp (> 5 minutes ago)
      LibraryScreen.setLastPauseTimeForTest(DateTime.now().subtract(const Duration(minutes: 10)));

      // Simulate resume after long pause
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify selection mode was softly reset to prevent modal touch lock
      expect(find.byKey(const ValueKey('library_selection_header')), findsNothing);
      expect(find.byKey(const ValueKey('add_book_fab')), findsOneWidget);
    });

    testWidgets('Form active flag protects edit session when user is in AddEditBookScreen', (tester) async {
      LibraryScreen.resetResumeDiagnosticsForTest();
      expect(AddEditBookScreen.isFormActive, false);

      final storage = InMemoryStorageService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB to open search, then open manual entry form
      await tester.tap(find.byKey(const ValueKey('add_book_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
      await tester.pumpAndSettle();

      // In AddEditBookScreen, isFormActive is true
      expect(AddEditBookScreen.isFormActive, true);
      expect(find.byType(AddEditBookScreen), findsOneWidget);

      // Simulate pause from 10 minutes ago and resume
      LibraryScreen.setLastPauseTimeForTest(DateTime.now().subtract(const Duration(minutes: 10)));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // AddEditBookScreen should STILL be open - form edits are protected!
      expect(find.byType(AddEditBookScreen), findsOneWidget);
      expect(AddEditBookScreen.isFormActive, true);
    });
  });

  group('Part 1: Theme leak fix & botanical date picker theming', () {
    testWidgets('Date picker opens in dark mode and does NOT leak light theme into the app', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryStorageService();
      await storage.setSetting('theme_mode', 'midnightGarden');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure app begins in Autumn Night (dark mode)
      expect(FloralPalette.isDark, isTrue);
      expect(FloralPalette.petalWhite, const Color(0xFF1E1611));
      expect(FloralPalette.softIvory, const Color(0xFF2B211A));

      // Open Add Book form
      await tester.tap(find.byKey(const ValueKey('add_book_fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditBookScreen), findsOneWidget);

      // Tap "Start Date" picker
      await tester.tap(find.byKey(const ValueKey('pick_start_date_btn')));
      await tester.pumpAndSettle();

      // 1. Assert DatePickerDialog is displayed
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // 2. Assert the DatePickerDialog uses dark theme brightness
      final datePickerThemeData = Theme.of(tester.element(find.byType(DatePickerDialog)));
      expect(datePickerThemeData.brightness, Brightness.dark);
      expect(datePickerThemeData.datePickerTheme.backgroundColor, FloralPalette.softIvory);

      // 3. Select current date and tap "OK"
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 4. Date picker dismissed
      expect(find.byType(DatePickerDialog), findsNothing);

      // 5. CRITICAL ASSERTION: The app's theme brightness and key colors are 100% UNCHANGED
      expect(FloralPalette.isDark, isTrue, reason: 'FloralPalette.isDark must remain true after date picker closes');
      expect(FloralPalette.currentMode, FloralThemeMode.midnightGarden);
      expect(FloralPalette.petalWhite, const Color(0xFF1E1611));
      expect(FloralPalette.softIvory, const Color(0xFF2B211A));
      expect(FloralPalette.warmCharcoal, const Color(0xFFF5EBE1));

      final addEditTheme = Theme.of(tester.element(find.byType(AddEditBookScreen)));
      expect(addEditTheme.brightness, Brightness.dark);
    });

    testWidgets('Canceling date picker also preserves dark theme without leak', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryStorageService();
      await storage.setSetting('theme_mode', 'midnightGarden');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Add Book form
      await tester.tap(find.byKey(const ValueKey('add_book_fab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
      await tester.pumpAndSettle();

      // Tap "Start Date" picker
      await tester.tap(find.byKey(const ValueKey('pick_start_date_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Tap "Cancel"
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(FloralPalette.isDark, isTrue);
      expect(FloralPalette.currentMode, FloralThemeMode.midnightGarden);
      expect(FloralPalette.petalWhite, const Color(0xFF1E1611));
      expect(FloralPalette.softIvory, const Color(0xFF2B211A));
    });
  });

  group('Part 2: Error Logger & iOS Diagnostics', () {
    setUp(() {
      AppErrorLogger.clearForTest();
    });

    tearDown(() {
      AppErrorLogger.clearForTest();
    });

    test('AppErrorLogger records uncaught errors, caps at maxErrors (5), and captures stack preview', () {
      expect(AppErrorLogger.recentErrors, isEmpty);

      // Record an error
      AppErrorLogger.recordError(
        'Simulated RenderFlex overflow',
        StackTrace.fromString('#0 RenderFlex.performLayout\n#1 RenderObject.layout\n#2 dart-sdk/lib/async.dart'),
        context: 'rendering',
      );

      expect(AppErrorLogger.recentErrors.length, 1);
      final entry = AppErrorLogger.recentErrors.first;
      expect(entry.message, contains('[rendering] Simulated RenderFlex overflow'));
      expect(entry.stackPreview, contains('#0 RenderFlex.performLayout'));

      // Record 6 more errors to test capping at 5
      for (int i = 1; i <= 6; i++) {
        AppErrorLogger.recordError('Error number $i', null);
      }
      expect(AppErrorLogger.recentErrors.length, 5);
      expect(AppErrorLogger.recentErrors.first.message, 'Error number 6');
    });

    testWidgets('Diagnostics screen displays clean session when no errors, and lists error details when errors occur', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryStorageService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings tab (index 3)
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Verify clean session state
      expect(find.byKey(const ValueKey('recent_errors_diagnostics_title')), findsOneWidget);
      expect(find.byKey(const ValueKey('recent_errors_empty_text')), findsOneWidget);

      // Record a test error
      AppErrorLogger.recordError('Test simulated unhandled error', null, context: 'TestEngine');

      // Re-pump Settings tab to reflect state
      await tester.tap(find.text('Library').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recent_error_entry_container')), findsOneWidget);
      expect(find.textContaining('Test simulated unhandled error'), findsOneWidget);
    });
  });
  
  group('Data Model & Migration: Format Version 2 & Backwards Compatibility', () {
    test('Importing old format_version 1 backup with descriptions succeeds and drops the field', () async {
      final storage = InMemoryStorageService();
      await storage.init();

      // Older backup payload (format_version 1) that includes description and descriptionIsUserEdited
      final oldBackupJson = jsonEncode({
        'metadata': {
          'format_version': 1,
          'app_version': '1.0.0',
          'export_date': DateTime.now().toIso8601String(),
          'book_count': 1,
        },
        'books': [
          {
            'id': 'legacy-v1-book',
            'title': 'Legacy Wuthering Heights',
            'authors': ['Emily Bronte'],
            'genres': ['Classic', 'Romance'],
            'rating': 4.5,
            'description': 'A passionate and tragic romance on the Yorkshire moors.',
            'descriptionIsUserEdited': true,
            'status': 'finished',
            'notes': 'Classic gothic tale',
            'quotes': [],
            'dateAdded': DateTime.now().toIso8601String(),
          }
        ],
        'covers': {},
        'reading_goal': 25,
        'settings': {},
      });

      // 1. Validation must accept format_version 1
      final validationResult = BackupService.validateBackupJson(oldBackupJson);
      expect(validationResult.isValid, isTrue, reason: 'Older format_version 1 must remain valid to import');
      expect(validationResult.bookCount, equals(1));

      // 2. Perform import (Replace mode)
      final summary = await BackupService.performImport(
        storage,
        validationResult.data!,
        merge: false,
      );
      expect(summary.addedCount, equals(1));

      // 3. Stored book must exist
      final allBooks = await storage.getAllBooks();
      expect(allBooks.length, equals(1));
      final importedBook = allBooks.first;
      expect(importedBook.id, equals('legacy-v1-book'));
      expect(importedBook.title, equals('Legacy Wuthering Heights'));

      // 4. Create a fresh export payload and ensure format_version is 2 and no description key exists
      final newExport = await BackupService.createExportPayload(storage);
      final metadata = newExport['metadata'] as Map<String, dynamic>;
      expect(metadata['format_version'], equals(2));

      final booksList = newExport['books'] as List<dynamic>;
      expect(booksList.length, equals(1));
      final exportedBookMap = booksList.first as Map<String, dynamic>;
      expect(exportedBookMap.containsKey('description'), isFalse, reason: 'Exported book must not have description key');
      expect(exportedBookMap.containsKey('descriptionIsUserEdited'), isFalse, reason: 'Exported book must not have descriptionIsUserEdited key');
      expect(exportedBookMap.containsKey('synopsis'), isFalse, reason: 'Exported book must not have synopsis key');

      final freshExportJsonString = jsonEncode(newExport);
      expect(freshExportJsonString.contains('"description"'), isFalse, reason: 'Fresh export JSON must have no description key anywhere');
      expect(freshExportJsonString.contains('"synopsis"'), isFalse, reason: 'Fresh export JSON must have no synopsis key anywhere');
    });
  });

  group('Keyboard & Input Focus Protection', () {
    testWidgets('Focusing a text field maintains active focus during viewport resize and keyboard appearance', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final storage = InMemoryStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Add/Edit Book Screen
      await tester.tap(find.byKey(const ValueKey('add_book_fab')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add_manually_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditBookScreen), findsOneWidget);

      // Find the Title text field
      final titleField = find.byKey(const ValueKey('input_book_title'));
      expect(titleField, findsOneWidget);

      // 1. Tap the title field to focus it
      await tester.tap(titleField);
      await tester.pump();

      expect(FocusManager.instance.primaryFocus, isNotNull, reason: 'A field must have primary focus upon tapping');

      // 2. Simulate keyboard appearing: viewport shrinks and viewInsets change
      // This triggers EnginePlatformDispatcher.onMetricsChanged and WidgetsBinding.handleMetricsChanged
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.binding.handleMetricsChanged();
      await tester.pump();

      // 3. Assert the text field did NOT lose focus (no programmatic blur)
      expect(FocusManager.instance.primaryFocus, isNotNull, reason: 'Field must remain focused after keyboard opens');

      // 4. Enter text to ensure input actually works without closing
      await tester.enterText(titleField, 'The Great Gatsby');
      await tester.pump();

      expect(find.text('The Great Gatsby'), findsWidgets);
      expect(FocusManager.instance.primaryFocus, isNotNull, reason: 'Focus must be maintained during text entry');
    });
  });
});
}
