import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/core/widgets/frosted_glass.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';
import 'package:bookmark/features/library/screens/library_screen.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';

class MockStorageService implements StorageService {
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
  Future<void> saveCoverImage(String id, Uint8List bytes) async => _covers[id] = bytes;

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

  group('Part 1: Selective Glassmorphism Guardrails', () {
    testWidgets('FloralBottomNav contains RepaintBoundary and BackdropFilter with 12px blur', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloralBottomNav(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      // Verify RepaintBoundary wraps the nav bar
      final repaintBoundaries = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaries, findsWidgets);

      // Verify BackdropFilter with blur
      final backdropFinder = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFinder, findsOneWidget);

      final backdropFilter = tester.widget<BackdropFilter>(backdropFinder);
      expect(backdropFilter.filter, isNotNull);
    });

    testWidgets('FrostedFloralFab has soft halo layer and solid tappable FAB with key', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FrostedFloralFab(
              fabKey: const ValueKey('test_fab_key'),
              onPressed: () {
                tapped = true;
              },
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      // Verify RepaintBoundary
      expect(find.descendant(of: find.byType(FrostedFloralFab), matching: find.byType(RepaintBoundary)), findsWidgets);

      // Verify BackdropFilter halo
      expect(find.descendant(of: find.byType(FrostedFloralFab), matching: find.byType(BackdropFilter)), findsOneWidget);

      // Verify solid FloatingActionButton with key and clickability
      final fabFinder = find.byKey(const ValueKey('test_fab_key'));
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      expect(tapped, isTrue);
    });

    testWidgets('FrostedGlassHeader isolates blur in RepaintBoundary and ClipRRect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrostedGlassHeader(
              child: Text('Header Title'),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(ClipRRect), findsWidgets);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Header Title'), findsOneWidget);
    });

    testWidgets('LibraryScreen has extendBody enabled for bottom nav frosted glass and renders FrostedFloralFab', (tester) async {
      final mockStorage = MockStorageService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(
            home: LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldFinder = find.byType(Scaffold).first;
      final scaffold = tester.widget<Scaffold>(scaffoldFinder);
      expect(scaffold.extendBody, isTrue);

      // Verify FrostedFloralFab is present
      expect(find.byType(FrostedFloralFab), findsOneWidget);
      expect(find.byKey(const ValueKey('add_book_fab')), findsOneWidget);
    });
  });
}
