import 'dart:typed_data';
import '../models/book.dart';

/// Abstract storage contract for "Bookmark".
///
/// By interacting exclusively with this interface, all feature layers and UI code
/// remain completely independent of the underlying storage engine.
/// If storage behavior on iOS Safari ever requires switching engines (e.g. from Hive
/// to Drift, IndexedDB directly, or OPFS), only the implementation of this interface
/// changes—zero UI code is touched.
abstract class StorageService {
  /// Initializes the local database and opens required boxes/stores.
  Future<void> init();

  /// Retrieves all books currently stored.
  Future<List<Book>> getAllBooks();

  /// Retrieves a single book by its unique ID.
  Future<Book?> getBook(String id);

  /// Saves or updates a book entry.
  Future<void> saveBook(Book book);

  /// Deletes a book and any associated cached cover image.
  Future<void> deleteBook(String id);

  /// Saves binary cover image data for offline use.
  Future<void> saveCoverImage(String id, Uint8List imageBytes);

  /// Retrieves cached binary cover image data for a book.
  Future<Uint8List?> getCoverImage(String id);

  /// Deletes a cached cover image.
  Future<void> deleteCoverImage(String id);

  /// Reads an application setting by key.
  Future<dynamic> getSetting(String key, {dynamic defaultValue});

  /// Writes an application setting.
  Future<void> setSetting(String key, dynamic value);

  /// Exports the entire library and settings as a JSON-serializable Map.
  Future<Map<String, dynamic>> exportAllData();

  /// Restores library from a JSON map. If [merge] is true, adds new books without deleting existing.
  Future<void> importAllData(Map<String, dynamic> data, {bool merge = false});

  /// Requests persistent storage from the browser (navigator.storage.persist()).
  Future<bool> requestPersistentStorage();

  /// Checks whether storage persistence is already granted.
  Future<bool> isStoragePersistent();
}
