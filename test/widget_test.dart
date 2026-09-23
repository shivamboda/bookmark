import 'package:bookmark/features/library/screens/add_edit_book_screen.dart';
import 'package:bookmark/features/library/widgets/book_list_card.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
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
  Future<Map<String, dynamic>> exportAllData() async => {'books': []};

  @override
  Future<void> importAllData(Map<String, dynamic> data, {bool merge = false}) async {}

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
    expect(find.text('Added Sep 23'), findsOneWidget);
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
      description: 'Feyre has undergone more trials than one human could ever bear.',
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
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);

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
}
