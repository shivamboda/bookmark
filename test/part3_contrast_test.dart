import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/core/theme/palette.dart';
import 'package:bookmark/models/book.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/features/library/screens/book_detail_screen.dart';
import 'package:bookmark/features/library/screens/book_search_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MockStorage extends StorageService {
  final Map<String, Book> _books = {};
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
  Future<void> deleteBook(String id) async => _books.remove(id);
  @override
  Future<void> saveCoverImage(String id, Uint8List imageBytes) async {}
  @override
  Future<Uint8List?> getCoverImage(String id) async => null;
  @override
  Future<void> deleteCoverImage(String id) async {}
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

double _relLuminance(Color color) {
  double adjust(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = adjust(color.r);
  final g = adjust(color.g);
  final b = adjust(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final l1 = _relLuminance(c1);
  final l2 = _relLuminance(c2);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

Color _blend(Color fg, Color bg) {
  final a = fg.a;
  return Color.from(
    alpha: 1.0,
    red: fg.r * a + bg.r * (1 - a),
    green: fg.g * a + bg.g * (1 - a),
    blue: fg.b * a + bg.b * (1 - a),
  );
}

void main() {
  group('Part 3: Contrast Fixes & Systemic Readability Verification', () {
    test('Token contrast measurements exceed 4.5:1 in both Dark and Light modes', () {
      for (final mode in [FloralThemeMode.midnightGarden, FloralThemeMode.poppyBlush]) {
        FloralPalette.currentMode = mode;
        final modeName = mode == FloralThemeMode.midnightGarden ? 'Dark' : 'Light';

        // 1. Page count pill text on kraftPaper
        final pageOnKraft = _contrastRatio(FloralPalette.pageCountText, FloralPalette.kraftPaper);
        expect(pageOnKraft, greaterThanOrEqualTo(4.5),
            reason: '$modeName mode: page count text on kraftPaper is $pageOnKraft:1');

        // 2. Page count pill text on latte blend
        final latteBg = _blend(FloralPalette.latte.withValues(alpha: 0.4), FloralPalette.softIvory);
        final pageOnLatte = _contrastRatio(FloralPalette.pageCountText, latteBg);
        expect(pageOnLatte, greaterThanOrEqualTo(4.5),
            reason: '$modeName mode: page count text on latte is $pageOnLatte:1');

        // 3. Save to Wishlist action button text on actionButtonFill
        final wishlistAction = _contrastRatio(FloralPalette.actionButtonText, FloralPalette.actionButtonFill);
        expect(wishlistAction, greaterThanOrEqualTo(4.5),
            reason: '$modeName mode: wishlist button text on fill is $wishlistAction:1');

        // 4. "tap to update" hint text (cocoa) on softIvory
        final tapToUpdate = _contrastRatio(FloralPalette.cocoa, FloralPalette.softIvory);
        expect(tapToUpdate, greaterThanOrEqualTo(4.5),
            reason: '$modeName mode: tap to update (cocoa) on softIvory is $tapToUpdate:1');

        // 5. Genre pill text (warmCharcoal) on blushPink 0.25 blend
        final genreBg = _blend(FloralPalette.blushPink.withValues(alpha: 0.25), FloralPalette.softIvory);
        final genrePill = _contrastRatio(FloralPalette.warmCharcoal, genreBg);
        expect(genrePill, greaterThanOrEqualTo(4.5),
            reason: '$modeName mode: genre pill text on blushPink blend is $genrePill:1');
      }
    });

    testWidgets('BookDetailScreen renders page count, tap-to-update, and genre pills with high contrast', (tester) async {
      FloralPalette.currentMode = FloralThemeMode.midnightGarden;
      final storage = _MockStorage();
      final testBook = Book(
        id: 'test-contrast-1',
        title: 'Pride and Prejudice',
        authors: const ['Jane Austen'],
        dateAdded: DateTime(2026, 1, 1),
        pageCount: 291,
        genres: const ['Classic', 'Romance'],
        status: ReadingStatus.reading,
        rating: 4.5,
      );
      await storage.saveBook(testBook);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: MaterialApp(
            home: BookDetailScreen(bookId: testBook.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "291 pages" pill is displayed
      expect(find.text('291 pages'), findsOneWidget);
      final pageTextWidget = tester.widget<Text>(find.text('291 pages'));
      expect(pageTextWidget.style?.color, FloralPalette.pageCountText);

      // Verify "tap to update" hint text is displayed
      expect(find.text('tap to update'), findsOneWidget);
      final tapWidget = tester.widget<Text>(find.text('tap to update'));
      expect(tapWidget.style?.color, FloralPalette.cocoa);

      // Verify "Classic" genre pill is displayed
      expect(find.text('Classic'), findsOneWidget);
    });

    testWidgets('BookSearchScreen renders search screen and action tokens cleanly', (tester) async {
      FloralPalette.currentMode = FloralThemeMode.midnightGarden;
      final storage = _MockStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: BookSearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify search screen loaded
      expect(find.byType(BookSearchScreen), findsOneWidget);
    });
  });
}
