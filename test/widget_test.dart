import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/core/state/providers.dart';

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
  testWidgets('Bookmark initial smoke test with in-memory storage', (WidgetTester tester) async {
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

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify app title appears
    expect(find.text('Bookmark'), findsOneWidget);
    // Verify book from storage appears
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsOneWidget);
  });
}
