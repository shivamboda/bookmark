import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/features/library/widgets/library_empty_state.dart';

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
    expect(find.text('BOOKMARK • READING JOURNAL'), findsOneWidget);

    // 2. Verify Book card in List view (matches both card title and cover placeholder)
    expect(find.byKey(const ValueKey('library_list_view')), findsOneWidget);
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsWidgets);
    expect(find.text('Taylor Jenkins Reid'), findsOneWidget);
    expect(find.text('Finished'), findsWidgets); // Status badge and filter chip

    // 3. Verify Bottom Navigation Tabs exist
    expect(find.text('Wishlist'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // 4. Test List / Grid toggle
    final toggleBtn = find.byKey(const ValueKey('view_mode_toggle_btn'));
    expect(toggleBtn, findsOneWidget);
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    // Verify Grid view is now rendered
    expect(find.byKey(const ValueKey('library_grid_view')), findsOneWidget);
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsWidgets);

    // Toggle back to List view
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library_list_view')), findsOneWidget);

    // 5. Test all 4 bottom navigation tabs work & switch screens
    // Tap Wishlist tab
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('BOOKMARK • WISHLIST'), findsOneWidget);

    // Tap Stats tab
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('BOOKMARK • READING STATS'), findsOneWidget);
    expect(find.text('2026 Reading Goal'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('BOOKMARK • SETTINGS'), findsOneWidget);
    expect(find.text('Yearly Reading Goal'), findsOneWidget);

    // Tap Library tab back
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(find.text('BOOKMARK • READING JOURNAL'), findsOneWidget);
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

    // Verify empty state message
    expect(find.byType(LibraryEmptyState), findsOneWidget);
    expect(find.text('Your shelf is waiting for its first story'), findsOneWidget);
  });
}
