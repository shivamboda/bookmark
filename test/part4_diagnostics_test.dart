import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/core/state/providers.dart';
import 'package:bookmark/services/storage_service.dart';
import 'package:bookmark/services/backup_service.dart';
import 'package:bookmark/services/error_logger.dart';
import 'package:bookmark/features/library/screens/library_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bookmark/models/book.dart';

class _MockStorage extends StorageService {
  final Map<String, dynamic> _settings = {};

  @override
  Future<void> init() async {}
  @override
  Future<List<Book>> getAllBooks() async => [];
  @override
  Future<Book?> getBook(String id) async => null;
  @override
  Future<void> saveBook(Book book) async {}
  @override
  Future<void> deleteBook(String id) async {}
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

void main() {
  group('Part 4: Hide Resolved Diagnostics Info from Settings View', () {
    testWidgets('Advanced diagnostics tile exists and keeps debug info inside an expander', (tester) async {
      LibraryScreen.resetResumeDiagnosticsForTest();
      final storage = _MockStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Verify the Advanced Diagnostics expander is present with title & subtitle
      final tileFinder = find.byKey(const ValueKey('advanced_diagnostics_tile'));
      expect(tileFinder, findsOneWidget);
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();

      expect(find.text('Advanced Diagnostics'), findsOneWidget);
      expect(find.text('Developer and troubleshooting info'), findsOneWidget);

      // Verify buttons become accessible when expanded
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      final copyBtn = find.byKey(const ValueKey('copy_diagnostics_button'));
      final reportBtn = find.byKey(const ValueKey('report_problem_button'));
      await tester.ensureVisible(copyBtn);
      await tester.pumpAndSettle();

      expect(copyBtn, findsOneWidget);
      expect(reportBtn, findsOneWidget);
      expect(find.byKey(const ValueKey('resume_events_diagnostics_text')), findsOneWidget);
    });

    testWidgets('Copy Diagnostics and Report Problem dialog work cleanly and include telemetry', (tester) async {
      LibraryScreen.resetResumeDiagnosticsForTest();
      AppErrorLogger.recordError('Simulated telemetry test error', null, context: 'Part4Test');
      final storage = _MockStorage();

      String? copiedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedClipboardText = (methodCall.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWithValue(storage)],
          child: const BookmarkApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();

      // Open Advanced Diagnostics
      final tileFinder = find.byKey(const ValueKey('advanced_diagnostics_tile'));
      await tester.ensureVisible(tileFinder);
      await tester.pumpAndSettle();
      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // Tap Copy Diagnostics
      final copyBtn = find.byKey(const ValueKey('copy_diagnostics_button'));
      await tester.ensureVisible(copyBtn);
      await tester.pumpAndSettle();
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      // Verify clipboard payload contains all required diagnostics
      expect(copiedClipboardText, isNotNull);
      expect(copiedClipboardText!, contains('Bookmark Diagnostics Report'));
      expect(copiedClipboardText!, contains('Resume Events:'));
      expect(copiedClipboardText!, contains('Simulated telemetry test error'));

      // Tap Report Problem
      final reportBtn = find.byKey(const ValueKey('report_problem_button'));
      await tester.ensureVisible(reportBtn);
      await tester.pumpAndSettle();
      await tester.tap(reportBtn);
      await tester.pumpAndSettle();

      // Verify modal dialog opens
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.byKey(const ValueKey('dialog_copy_diagnostics_btn')), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Report a Problem'), findsNothing);
    });
  });
}
