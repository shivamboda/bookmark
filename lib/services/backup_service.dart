import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/book.dart';
import 'backup_transport.dart';
import 'storage_service.dart';

/// Validation result of a backup JSON payload.
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? data;
  final int bookCount;
  final int quotesCount;
  final int coversCount;
  final int? readingGoal;

  const BackupValidationResult.valid({
    required this.data,
    required this.bookCount,
    required this.quotesCount,
    required this.coversCount,
    this.readingGoal,
  })  : isValid = true,
        errorMessage = null;

  const BackupValidationResult.invalid(this.errorMessage)
      : isValid = false,
        data = null,
        bookCount = 0,
        quotesCount = 0,
        coversCount = 0,
        readingGoal = null;
}

/// Summary report returned after performing a Merge or Replace import.
class ImportSummary {
  final bool isReplace;
  final int addedCount;
  final int updatedCount;
  final int keptExistingCount;
  final int skippedDuplicatesCount;
  final int totalBooksInLibrary;
  final int restoredCoversCount;
  final int? restoredGoal;

  const ImportSummary({
    required this.isReplace,
    required this.addedCount,
    required this.updatedCount,
    required this.keptExistingCount,
    required this.skippedDuplicatesCount,
    required this.totalBooksInLibrary,
    required this.restoredCoversCount,
    this.restoredGoal,
  });

  String toUserMessage() {
    if (isReplace) {
      return 'Library successfully restored with $totalBooksInLibrary books and $restoredCoversCount covers.';
    } else {
      final parts = <String>[];
      if (addedCount > 0) parts.add('$addedCount new books added');
      if (updatedCount > 0) parts.add('$updatedCount existing updated');
      if (skippedDuplicatesCount > 0) {
        parts.add('$skippedDuplicatesCount possible duplicates skipped');
      }
      if (parts.isEmpty) return 'Library is already up to date.';
      return 'Import complete: ${parts.join(', ')}.';
    }
  }
}

/// Comprehensive service for library Backup, Export, Validation, and Atomic Import.
class BackupService {
  static const int currentFormatVersion = 1;
  static const String currentAppVersion = '1.0.0';

  /// Serializes all books, binary cover images, reading goal, and settings into a JSON string.
  static Future<String> exportLibraryJson(StorageService storage) async {
    final payload = await createExportPayload(storage);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  /// Constructs the export payload map with metadata, books, base64 covers, and settings.
  static Future<Map<String, dynamic>> createExportPayload(StorageService storage) async {
    await storage.init();
    final books = await storage.getAllBooks();

    // 1. Collect all cached cover images (base64 encoded)
    final coversMap = <String, String>{};
    for (final book in books) {
      final bytes = await storage.getCoverImage(book.id) ?? book.coverBytes;
      if (bytes != null && bytes.isNotEmpty) {
        coversMap[book.id] = base64Encode(bytes);
      }
    }

    // 2. Reading goal and key settings
    final yearlyGoal = await storage.getSetting('yearly_goal');
    final settingsMap = <String, dynamic>{};
    for (final key in [
      'library_sort_option',
      'library_is_grid_view',
      'theme_mode',
      'yearly_goal',
      'has_seeded_sample_data',
    ]) {
      final val = await storage.getSetting(key);
      if (val != null) {
        settingsMap[key] = val;
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    await storage.setSetting('last_backup_date', nowIso);

    return {
      'metadata': {
        'format_version': currentFormatVersion,
        'app_version': currentAppVersion,
        'export_date': nowIso,
        'book_count': books.length,
      },
      'books': books.map((b) => b.toMap()).toList(),
      'covers': coversMap,
      'reading_goal': yearlyGoal,
      'settings': settingsMap,
    };
  }

  /// Initiates file download or Web Share.
  static Future<bool> downloadOrShareBackup({
    required String jsonContent,
    String? customFileName,
    bool preferShare = false,
  }) async {
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = customFileName ?? 'bookmark_backup_$dateStr.json';
    return saveOrShareBackupPlatform(
      jsonContent: jsonContent,
      fileName: fileName,
      preferShare: preferShare,
    );
  }

  /// Completely validates an imported backup JSON string BEFORE writing anything to storage.
  static BackupValidationResult validateBackupJson(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return const BackupValidationResult.invalid('The file is empty. Please choose a valid Bookmark backup.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (_) {
      return const BackupValidationResult.invalid(
        'The selected file is not a valid JSON document. Please ensure it was exported from Bookmark.',
      );
    }

    if (decoded is! Map) {
      return const BackupValidationResult.invalid(
        'The backup file does not contain a valid Bookmark data structure.',
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    // Format version verification
    final metadata = data['metadata'];
    final formatVersion = (metadata is Map) ? metadata['format_version'] : data['version'];

    if (formatVersion == null || formatVersion != currentFormatVersion) {
      return BackupValidationResult.invalid(
        'Unsupported backup format (version ${formatVersion ?? "unknown"}). This version of Bookmark requires format version $currentFormatVersion.',
      );
    }

    // Required books field verification
    final booksRaw = data['books'];
    if (booksRaw is! List) {
      return const BackupValidationResult.invalid(
        'The backup file is missing its book collection.',
      );
    }

    int quotesCount = 0;
    for (int i = 0; i < booksRaw.length; i++) {
      final item = booksRaw[i];
      if (item is! Map) {
        return BackupValidationResult.invalid(
          'Book record #${i + 1} is corrupted or not in the expected format.',
        );
      }
      final id = item['id']?.toString();
      final title = item['title']?.toString();
      if (id == null || id.trim().isEmpty || title == null || title.trim().isEmpty) {
        return BackupValidationResult.invalid(
          'Book record #${i + 1} is missing a required title or identifier.',
        );
      }
      final quotes = item['quotes'];
      if (quotes is List && quotes.isNotEmpty) {
        quotesCount += quotes.length;
      }
    }

    // Validate covers if present
    int coversCount = 0;
    if (data['covers'] != null) {
      if (data['covers'] is! Map) {
        return const BackupValidationResult.invalid(
          'The cover images section in this backup is corrupted.',
        );
      }
      coversCount = (data['covers'] as Map).length;
    }

    final int? readingGoal = data['reading_goal'] as int? ??
        (data['settings'] is Map ? (data['settings'] as Map)['yearly_goal'] as int? : null);

    return BackupValidationResult.valid(
      data: data,
      bookCount: booksRaw.length,
      quotesCount: quotesCount,
      coversCount: coversCount,
      readingGoal: readingGoal,
    );
  }

  /// Performs an atomic import of the backup data.
  ///
  /// If [merge] is false (Replace):
  /// - Completely replaces all existing books, covers, reading goal, and settings.
  ///
  /// If [merge] is true:
  /// - Matches by book id.
  /// - Existing ids are kept UNLESS imported record is newer (compares dateAdded timestamp).
  /// - New ids are added.
  /// - If an imported book has a different id, but the exact same title & author as an existing book,
  ///   it is skipped and counted as a possible duplicate.
  static Future<ImportSummary> performImport(
    StorageService storage,
    Map<String, dynamic> data, {
    required bool merge,
  }) async {
    await storage.init();

    // 1. Pre-parse and validate everything in memory first (guaranteeing atomicity)
    final booksRaw = data['books'] as List? ?? [];
    final parsedBooks = <Book>[];
    for (final raw in booksRaw) {
      final map = Map<String, dynamic>.from(raw as Map);
      parsedBooks.add(Book.fromMap(map));
    }

    final coversRaw = data['covers'] as Map? ?? {};
    final parsedCovers = <String, Uint8List>{};
    for (final entry in coversRaw.entries) {
      try {
        final bytes = base64Decode(entry.value.toString());
        parsedCovers[entry.key.toString()] = bytes;
      } catch (e) {
        debugPrint('Warning: Could not decode base64 cover for ${entry.key}: $e');
      }
    }

    final int? readingGoal = data['reading_goal'] as int? ??
        (data['settings'] is Map ? (data['settings'] as Map)['yearly_goal'] as int? : null);
    final settingsMap = (data['settings'] is Map) ? Map<String, dynamic>.from(data['settings'] as Map) : null;

    if (!merge) {
      // ==========================================
      // REPLACE MODE: Complete wipe and restore
      // ==========================================
      final existingBooks = await storage.getAllBooks();
      for (final book in existingBooks) {
        await storage.deleteBook(book.id);
        await storage.deleteCoverImage(book.id);
      }

      // Save all books
      for (final book in parsedBooks) {
        await storage.saveBook(book);
      }

      // Save all covers
      for (final entry in parsedCovers.entries) {
        await storage.saveCoverImage(entry.key, entry.value);
      }

      // Restore goal and settings
      if (readingGoal != null) {
        await storage.setSetting('yearly_goal', readingGoal);
      }
      if (settingsMap != null) {
        for (final entry in settingsMap.entries) {
          await storage.setSetting(entry.key, entry.value);
        }
      }

      // Record backup timestamp
      await storage.setSetting('last_backup_date', DateTime.now().toIso8601String());

      return ImportSummary(
        isReplace: true,
        addedCount: parsedBooks.length,
        updatedCount: 0,
        keptExistingCount: 0,
        skippedDuplicatesCount: 0,
        totalBooksInLibrary: parsedBooks.length,
        restoredCoversCount: parsedCovers.length,
        restoredGoal: readingGoal,
      );
    } else {
      // ==========================================
      // MERGE MODE: Smart ID match & duplicate avoidance
      // ==========================================
      final existingBooks = await storage.getAllBooks();
      final existingById = {for (final b in existingBooks) b.id: b};

      // Title + Author display key for detecting duplicates with different IDs
      String normalize(String s) => s.trim().toLowerCase();
      String bookKey(String title, String author) => '${normalize(title)}|${normalize(author)}';

      final existingTitleAuthors = {
        for (final b in existingBooks) bookKey(b.title, b.authorDisplay): b.id,
      };

      int addedCount = 0;
      int updatedCount = 0;
      int keptExistingCount = 0;
      int skippedDuplicatesCount = 0;

      final booksToSave = <Book>[];
      final coversToSave = <String, Uint8List>{};

      for (final importedBook in parsedBooks) {
        final existingBook = existingById[importedBook.id];

        if (existingBook != null) {
          // Existing ID: keep existing UNLESS imported is newer
          final isImportedNewer = importedBook.dateAdded.isAfter(existingBook.dateAdded);
          if (isImportedNewer) {
            booksToSave.add(importedBook);
            updatedCount++;
            if (parsedCovers.containsKey(importedBook.id)) {
              coversToSave[importedBook.id] = parsedCovers[importedBook.id]!;
            }
          } else {
            keptExistingCount++;
          }
        } else {
          // New ID: check if another book has the same title and author
          final key = bookKey(importedBook.title, importedBook.authorDisplay);
          if (existingTitleAuthors.containsKey(key)) {
            // Skip to avoid silent duplication
            skippedDuplicatesCount++;
          } else {
            booksToSave.add(importedBook);
            addedCount++;
            existingTitleAuthors[key] = importedBook.id;
            if (parsedCovers.containsKey(importedBook.id)) {
              coversToSave[importedBook.id] = parsedCovers[importedBook.id]!;
            }
          }
        }
      }

      // Commit to storage
      for (final book in booksToSave) {
        await storage.saveBook(book);
      }
      for (final entry in coversToSave.entries) {
        await storage.saveCoverImage(entry.key, entry.value);
      }

      // Record backup timestamp
      await storage.setSetting('last_backup_date', DateTime.now().toIso8601String());

      final updatedTotalBooks = await storage.getAllBooks();

      return ImportSummary(
        isReplace: false,
        addedCount: addedCount,
        updatedCount: updatedCount,
        keptExistingCount: keptExistingCount,
        skippedDuplicatesCount: skippedDuplicatesCount,
        totalBooksInLibrary: updatedTotalBooks.length,
        restoredCoversCount: coversToSave.length,
        restoredGoal: readingGoal,
      );
    }
  }
}
