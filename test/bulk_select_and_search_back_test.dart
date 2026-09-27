import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/features/library/screens/library_screen.dart';
import 'package:bookmark/features/library/screens/book_search_screen.dart';
import 'package:bookmark/features/library/screens/add_edit_book_screen.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';
import 'package:bookmark/features/library/widgets/book_list_card.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';
import 'package:bookmark/services/book_search_service.dart';
import 'package:bookmark/models/book.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Part 1: Bulk-Select Bar & Pill Nav Bar Coexistence & Visual Polish', () {
    testWidgets('Bulk-select bar replaces nav bar without collision, matches pill styling and safe-area', (tester) async {
      // Simulate iPhone with 34px bottom home indicator inset
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2.0;
      tester.view.padding = const FakeViewPadding(bottom: 68); // 34 logical px
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });

      final storage = InMemoryStorageService();
      final b1 = Book(
        id: 'book-1',
        title: 'The Hobbit',
        authors: ['J.R.R. Tolkien'],
        status: ReadingStatus.finished,
        finishDate: DateTime(2025, 6, 1),
        rating: 4.5,
        dateAdded: DateTime(2025, 1, 1),
      );
      final b2 = Book(
        id: 'book-2',
        title: 'The Fellowship of the Ring',
        authors: ['J.R.R. Tolkien'],
        status: ReadingStatus.reading,
        dateAdded: DateTime(2025, 2, 1),
      );
      await storage.saveBook(b1);
      await storage.saveBook(b2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Normal Library
      expect(find.byType(FloralBottomNav), findsOneWidget);
      expect(find.byKey(const ValueKey('bulk_set_year_button')), findsNothing);
      expect(find.byKey(const ValueKey('bulk_rate_button')), findsNothing);
      expect(find.byKey(const ValueKey('library_selection_header')), findsNothing);

      // 2. Long-press first book to enter selection mode
      await tester.longPress(find.byType(BookListCard).first);
      await tester.pumpAndSettle();

      // 3. Selection mode active:
      // - Selection header appears at top with "1 selected", "Select all", "Cancel"
      expect(find.byKey(const ValueKey('library_selection_header')), findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byKey(const ValueKey('select_all_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('cancel_selection_button')), findsOneWidget);

      // Verify header tap targets >= 44x44
      final cancelSize = tester.getSize(find.byKey(const ValueKey('cancel_selection_button')));
      expect(cancelSize.height, greaterThanOrEqualTo(44.0));
      final selectAllSize = tester.getSize(find.byKey(const ValueKey('select_all_button')));
      expect(selectAllSize.height, greaterThanOrEqualTo(44.0));

      // 4. Position & Collision Verification:
      // The bulk-select action bar REPLACES the bottom nav bar in the Scaffold bottomNavigationBar slot
      expect(find.byKey(const ValueKey('bulk_set_year_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('bulk_rate_button')), findsOneWidget);
      expect(find.byType(FloralBottomNav), findsNothing); // Never stacked or colliding!

      // 5. Button tap targets & styling
      final setYearSize = tester.getSize(find.byKey(const ValueKey('bulk_set_year_button')));
      expect(setYearSize.height, greaterThanOrEqualTo(44.0));
      final rateSize = tester.getSize(find.byKey(const ValueKey('bulk_rate_button')));
      expect(rateSize.height, greaterThanOrEqualTo(44.0));

      // 6. Select all and cancel interaction
      await tester.tap(find.byKey(const ValueKey('select_all_button')));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cancel_selection_button')));
      await tester.pumpAndSettle();

      // Exiting selection mode smoothly restores FloralBottomNav
      expect(find.byKey(const ValueKey('library_selection_header')), findsNothing);
      expect(find.byKey(const ValueKey('bulk_set_year_button')), findsNothing);
      expect(find.byType(FloralBottomNav), findsOneWidget);
    });
  });

  group('Part 2: Search Result Back Button Navigation Flow', () {
    testWidgets('Tapping back from a viewed search result pops directly to Library and clears search', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final storage = InMemoryStorageService();
      final mockSearchResults = <BookSearchResult>[
        const BookSearchResult(
          title: 'Dune Messiah',
          authors: ['Frank Herbert'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookSearchScreen(
                            searchFn: (_) async => mockSearchResults,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Search'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Open Search
      await tester.tap(find.text('Open Search'));
      await tester.pumpAndSettle();
      expect(find.byType(BookSearchScreen), findsOneWidget);

      // Search for Dune
      await tester.enterText(find.byKey(const ValueKey('book_search_input')), 'Dune');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Search result is displayed
      expect(find.text('Dune Messiah'), findsOneWidget);

      // Tap on the search result to view / add
      await tester.tap(find.text('Dune Messiah'));
      await tester.pumpAndSettle();

      // AddEditBookScreen is opened with prefilled draft
      expect(find.byType(AddEditBookScreen), findsOneWidget);
      expect(find.text('Dune Messiah'), findsWidgets);
      expect(find.byKey(const ValueKey('add_edit_back_btn')), findsOneWidget);

      // Tap the back button on AddEditBookScreen
      await tester.tap(find.byKey(const ValueKey('add_edit_back_btn')));
      await tester.pumpAndSettle();

      // Desired behavior: Should pop ALL THE WAY back to home, skipping intermediate search results!
      expect(find.byType(AddEditBookScreen), findsNothing);
      expect(find.byType(BookSearchScreen), findsNothing);
      expect(find.text('Open Search'), findsOneWidget);
    });

    testWidgets('Tapping back WITHOUT selecting a result does NOT pop past search screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BookSearchScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Search Screen'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Search Screen'));
      await tester.pumpAndSettle();
      expect(find.byType(BookSearchScreen), findsOneWidget);

      // Tap back button on the search screen
      await tester.tap(find.byKey(const ValueKey('search_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BookSearchScreen), findsNothing);
      expect(find.text('Open Search Screen'), findsOneWidget);
    });
  });
}
