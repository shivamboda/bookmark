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

    // Tap edit button to verify placeholder snackbar
    await tester.tap(editBtn);
    await tester.pump();
    expect(find.textContaining('Step 4c'), findsOneWidget);

    // 8. Test Back button pops back to Library
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
    expect(find.byType(BookDetailScreen), findsNothing);
    expect(find.text('Library'), findsNWidgets(2));
  });
}
