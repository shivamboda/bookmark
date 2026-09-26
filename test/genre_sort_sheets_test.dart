import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/features/library/screens/library_screen.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/core/widgets/frosted_glass.dart';

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

  testWidgets('Genre and Sort controls have >= 44px tap targets, warm botanical styling, and open bottom sheets with chips', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final storage = InMemoryStorageService();
    final testBooks = [
      Book(
        id: 'book-1',
        title: 'The Name of the Wind',
        authors: ['Patrick Rothfuss'],
        genres: ['Fantasy'],
        rating: 4.8,
        status: ReadingStatus.reading,
        dateAdded: DateTime(2026, 9, 1),
      ),
      Book(
        id: 'book-2',
        title: 'Project Hail Mary',
        authors: ['Andy Weir'],
        genres: ['Sci-Fi'],
        rating: 4.9,
        status: ReadingStatus.reading,
        dateAdded: DateTime(2026, 9, 5),
      ),
    ];

    for (final b in testBooks) {
      await storage.saveBook(b);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Genre Button size and styling
    final genreBtnFinder = find.byKey(const ValueKey('genre_filter_button'));
    expect(genreBtnFinder, findsOneWidget);
    final genreBtnSize = tester.getSize(genreBtnFinder);
    expect(genreBtnSize.height, greaterThanOrEqualTo(44.0));

    // Verify Sort Button size and styling
    final sortBtnFinder = find.byKey(const ValueKey('sort_option_button'));
    expect(sortBtnFinder, findsOneWidget);
    final sortBtnSize = tester.getSize(sortBtnFinder);
    expect(sortBtnSize.height, greaterThanOrEqualTo(44.0));

    // 2. Open Genre Filter Sheet
    await tester.tap(genreBtnFinder);
    await tester.pumpAndSettle();

    // Header & subtitle checks
    expect(find.text('Filter by Genre'), findsOneWidget);
    expect(find.text('find stories by theme ~'), findsOneWidget);
    expect(find.byType(FrostedGlassHeader), findsOneWidget);

    // Genre items are rendered as chips/pills
    final allGenresChip = find.byKey(const ValueKey('genre_item_all'));
    final fantasyChip = find.byKey(const ValueKey('genre_item_Fantasy'));
    final scifiChip = find.byKey(const ValueKey('genre_item_Sci-Fi'));

    expect(allGenresChip, findsOneWidget);
    expect(fantasyChip, findsOneWidget);
    expect(scifiChip, findsOneWidget);

    // Verify chip tap target size >= 44px
    final chipSize = tester.getSize(allGenresChip);
    expect(chipSize.height, greaterThanOrEqualTo(44.0));

    // Tap Fantasy chip
    await tester.tap(fantasyChip);
    await tester.pumpAndSettle();

    // Sheet should be closed
    expect(find.text('Filter by Genre'), findsNothing);
    // Fantasy book displayed, Sci-Fi book filtered out
    expect(find.text('The Name of the Wind'), findsWidgets);
    expect(find.text('Project Hail Mary'), findsNothing);

    // Active genre button shows 'Fantasy' and clear (x) button
    expect(find.text('Fantasy'), findsWidgets);
    expect(find.byKey(const ValueKey('clear_genre_chip_btn')), findsOneWidget);

    // Clear genre via clear button
    await tester.tap(find.byKey(const ValueKey('clear_genre_chip_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Project Hail Mary'), findsWidgets);

    // 3. Open Sort Option Sheet
    await tester.tap(sortBtnFinder);
    await tester.pumpAndSettle();

    // Header & subtitle checks
    expect(find.text('Sort Bookshelf'), findsOneWidget);
    expect(find.text('order your reading sanctuary ~'), findsOneWidget);
    expect(find.byType(FrostedGlassHeader), findsOneWidget);

    // Verify sort options rendered as cards
    final sortRatingOption = find.byKey(const ValueKey('sort_item_rating'));
    expect(sortRatingOption, findsOneWidget);
    final sortOptionSize = tester.getSize(sortRatingOption);
    expect(sortOptionSize.height, greaterThanOrEqualTo(44.0));

    // Tap sort by Rating
    await tester.tap(sortRatingOption);
    await tester.pumpAndSettle();

    // Sheet should be closed
    expect(find.text('Sort Bookshelf'), findsNothing);

    // Verify sort persisted
    final savedSort = await storage.getSetting('library_sort_option');
    expect(savedSort, 'rating');
  });
}
