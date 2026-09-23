import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/book.dart';
import 'storage_persistence.dart';
import 'storage_service.dart';

/// Concrete storage implementation using Hive CE (Community Edition).
///
/// Backed directly by browser IndexedDB on Web, with native support
/// for binary Uint8List storage, fast key-value lookups, and zero SQL overhead.
class HiveStorageService implements StorageService {
  static const String _booksBoxName = 'bookmark_books';
  static const String _coversBoxName = 'bookmark_covers';
  static const String _settingsBoxName = 'bookmark_settings';

  late Box<Map> _booksBox;
  late Box _coversBox;
  late Box _settingsBox;

  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _booksBox = await Hive.openBox<Map>(_booksBoxName);
    _coversBox = await Hive.openBox(_coversBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    _isInitialized = true;

    // DEBUG-ONLY SAMPLE SEEDING:
    // Only runs in debug mode on first install when the database is completely empty.
    // In production/release builds (kReleaseMode), this will never execute.
    // Setting 'has_seeded_sample_data' ensures it never re-seeds if books are deleted.
    final hasSeeded = await getSetting('has_seeded_sample_data', defaultValue: false);
    if (kDebugMode && !hasSeeded && _booksBox.isEmpty) {
      await _seedSampleLibrary();
      await setSetting('has_seeded_sample_data', true);
    }
  }

  @override
  Future<List<Book>> getAllBooks() async {
    if (!_isInitialized) await init();
    final books = <Book>[];

    for (final raw in _booksBox.values) {
      try {
        final map = Map<String, dynamic>.from(raw);
        books.add(Book.fromMap(map));
      } catch (e) {
        debugPrint('Error parsing book from Hive: $e');
      }
    }

    // Sort by date added (newest first)
    books.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return books;
  }

  @override
  Future<Book?> getBook(String id) async {
    if (!_isInitialized) await init();
    final raw = _booksBox.get(id);
    if (raw == null) return null;
    return Book.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> saveBook(Book book) async {
    if (!_isInitialized) await init();
    await _booksBox.put(book.id, book.toMap());
  }

  @override
  Future<void> deleteBook(String id) async {
    if (!_isInitialized) await init();
    await _booksBox.delete(id);
    await _coversBox.delete(id);
  }

  @override
  Future<void> saveCoverImage(String id, Uint8List imageBytes) async {
    if (!_isInitialized) await init();
    await _coversBox.put(id, imageBytes);
  }

  @override
  Future<Uint8List?> getCoverImage(String id) async {
    if (!_isInitialized) await init();
    final data = _coversBox.get(id);
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return null;
  }

  @override
  Future<void> deleteCoverImage(String id) async {
    if (!_isInitialized) await init();
    await _coversBox.delete(id);
  }

  @override
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    if (!_isInitialized) await init();
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> setSetting(String key, dynamic value) async {
    if (!_isInitialized) await init();
    await _settingsBox.put(key, value);
  }

  @override
  Future<Map<String, dynamic>> exportAllData() async {
    if (!_isInitialized) await init();
    final books = await getAllBooks();

    // Encode cover images into base64 for safe JSON transport
    final coversMap = <String, String>{};
    for (final key in _coversBox.keys) {
      final bytes = await getCoverImage(key.toString());
      if (bytes != null) {
        coversMap[key.toString()] = base64Encode(bytes);
      }
    }

    final settingsMap = <String, dynamic>{};
    for (final key in _settingsBox.keys) {
      settingsMap[key.toString()] = _settingsBox.get(key);
    }

    return {
      'app': 'Bookmark',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books.map((b) => b.toMap()).toList(),
      'covers': coversMap,
      'settings': settingsMap,
    };
  }

  @override
  Future<void> importAllData(Map<String, dynamic> data, {bool merge = false}) async {
    if (!_isInitialized) await init();

    if (!merge) {
      await _booksBox.clear();
      await _coversBox.clear();
    }

    // Restore books
    final booksRaw = data['books'] as List? ?? [];
    for (final item in booksRaw) {
      final bookMap = Map<String, dynamic>.from(item as Map);
      final book = Book.fromMap(bookMap);
      await _booksBox.put(book.id, book.toMap());
    }

    // Restore covers
    final coversRaw = data['covers'] as Map? ?? {};
    for (final entry in coversRaw.entries) {
      try {
        final bytes = base64Decode(entry.value.toString());
        await _coversBox.put(entry.key.toString(), bytes);
      } catch (e) {
        debugPrint('Error restoring cover image: $e');
      }
    }

    // Restore settings
    final settingsRaw = data['settings'] as Map? ?? {};
    for (final entry in settingsRaw.entries) {
      await _settingsBox.put(entry.key.toString(), entry.value);
    }
  }

  @override
  Future<bool> requestPersistentStorage() => requestStoragePersistence();

  @override
  Future<bool> isStoragePersistent() => checkStoragePersistence();

  /// Seeds initial sample library with popular romance, fantasy, and literary fiction
  Future<void> _seedSampleLibrary() async {
    final now = DateTime.now();

    final samples = [
      Book(
        id: 'seed-evelyn-hugo',
        title: 'The Seven Husbands of Evelyn Hugo',
        authors: ['Taylor Jenkins Reid'],
        genres: ['Historical Fiction', 'Romance', 'Drama'],
        rating: 4.5,
        status: ReadingStatus.finished,
        description:
            'Aging and reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life.',
        startDate: now.subtract(const Duration(days: 30)),
        finishDate: now.subtract(const Duration(days: 12)),
        notes: 'An absolute masterpiece of love, ambition, and sacrifice. The twist broke my heart.',
        pageCount: 400,
        quotes: [
          BookQuote(
            id: 'quote-eh-1',
            quote: 'People think that intimacy is about sex. But intimacy is about truth.',
            pageNumber: 184,
            createdAt: now.subtract(const Duration(days: 15)),
          ),
          BookQuote(
            id: 'quote-eh-2',
            quote: 'Make them pay you what they would pay a white man.',
            pageNumber: 260,
            createdAt: now.subtract(const Duration(days: 13)),
          ),
        ],
        dateAdded: now.subtract(const Duration(days: 30)),
      ),
      Book(
        id: 'seed-fourth-wing',
        title: 'Fourth Wing',
        authors: ['Rebecca Yarros'],
        genres: ['Fantasy', 'Romance', 'Dragons'],
        rating: 4.0,
        status: ReadingStatus.reading,
        description:
            'Twenty-year-old Violet Sorrengail was supposed to enter the Scribe Quadrant. Instead, her mother orders her to join the deadly dragon riders.',
        startDate: now.subtract(const Duration(days: 8)),
        notes: 'Fast-paced, dangerous, and the dragon bonds are incredible. Violet is fierce.',
        pageCount: 528,
        quotes: [
          BookQuote(
            id: 'quote-fw-1',
            quote: 'A dragon without its rider is a tragedy. A rider without their dragon is dead.',
            pageNumber: 42,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
        dateAdded: now.subtract(const Duration(days: 8)),
      ),
      Book(
        id: 'seed-tomorrow',
        title: 'Tomorrow, and Tomorrow, and Tomorrow',
        authors: ['Gabrielle Zevin'],
        genres: ['Literary Fiction', 'Contemporary'],
        rating: 5.0,
        status: ReadingStatus.finished,
        description:
            'Two childhood friends collaborate as video game designers, experiencing fame, joy, tragedy, and the enduring complexity of creative love.',
        startDate: now.subtract(const Duration(days: 60)),
        finishDate: now.subtract(const Duration(days: 35)),
        notes: 'One of the most poetic portraits of friendship and collaborative art ever written.',
        pageCount: 416,
        quotes: [
          BookQuote(
            id: 'quote-tt-1',
            quote:
                'To allow yourself to play with another person is no small risk. It means allowing yourself to be open, to be exposed, to be hurt.',
            pageNumber: 211,
            createdAt: now.subtract(const Duration(days: 40)),
          ),
        ],
        dateAdded: now.subtract(const Duration(days: 60)),
      ),
      Book(
        id: 'seed-pride-prejudice',
        title: 'Pride and Prejudice',
        authors: ['Jane Austen'],
        genres: ['Classic', 'Romance'],
        rating: 0.0,
        status: ReadingStatus.wantToRead,
        description:
            'The turbulent relationship between Elizabeth Bennet, the daughter of a country gentleman, and Fitzwilliam Darcy, a rich aristocratic landowner.',
        notes: 'Recommended by a friend for an autumn re-read.',
        pageCount: 432,
        dateAdded: now.subtract(const Duration(days: 4)),
      ),
      Book(
        id: 'seed-song-achilles',
        title: 'The Song of Achilles',
        authors: ['Madeline Miller'],
        genres: ['Mythology', 'Romance', 'Historical'],
        rating: 0.0,
        status: ReadingStatus.wantToRead,
        description:
            'A tale of gods, kings, immortal fame, and the human heart, retelling Homer’s Iliad from the perspective of Patroclus.',
        notes: 'Heard this makes you cry like a baby. Next on my list!',
        pageCount: 416,
        dateAdded: now.subtract(const Duration(days: 2)),
      ),
    ];

    for (final book in samples) {
      await _booksBox.put(book.id, book.toMap());
    }
  }
}


