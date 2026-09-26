import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../services/storage_service.dart';
import '../../services/hive_storage_service.dart';
import '../theme/palette.dart';

/// Global shared instance of HiveStorageService.
/// Guarantees the provider always resolves to a valid, working instance
/// even before overrides or across hot reloads.
final globalStorageService = HiveStorageService();

/// Provider for the StorageService instance.
final storageServiceProvider = Provider<StorageService>((ref) {
  return globalStorageService;
});

/// Manages active floral theme mode (defaults to Poppy Blush).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, FloralThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<FloralThemeMode> {
  @override
  FloralThemeMode build() {
    _loadTheme();
    return FloralThemeMode.midnightGarden;
  }

  Future<void> _loadTheme() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final saved = await storage.getSetting('theme_mode', defaultValue: 'midnightGarden');
      final match = FloralThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => FloralThemeMode.midnightGarden,
      );
      FloralPalette.currentMode = match;
      state = match;
    } catch (_) {
      state = FloralThemeMode.midnightGarden;
    }
  }

  Future<void> setTheme(FloralThemeMode mode) async {
    FloralPalette.currentMode = mode;
    state = mode;
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting('theme_mode', mode.name);
  }
}

/// Manages optional yearly reading goal (e.g. 25 books).
/// Persisted in storage, null if user opts out.
final yearlyGoalProvider = NotifierProvider<YearlyGoalNotifier, int?>(YearlyGoalNotifier.new);

class YearlyGoalNotifier extends Notifier<int?> {
  @override
  int? build() {
    _loadGoal();
    return null;
  }

  Future<void> _loadGoal() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final saved = await storage.getSetting('yearly_goal');
      if (saved is int) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> setGoal(int? goal) async {
    state = goal;
    final storage = ref.read(storageServiceProvider);
    await storage.setSetting('yearly_goal', goal);
  }
}

/// Primary library books async notifier.
final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final storage = ref.watch(storageServiceProvider);
    // Ensure storage is initialized if called before or during main init
    await storage.init();
    return storage.getAllBooks();
  }

  Future<void> addBook(Book book) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBook(book);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateBook(Book book) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBook(book);
    ref.invalidateSelf();
    await future;
  }

  /// Bulk updates multiple books in storage with a single invalidation.
  Future<void> bulkUpdateBooks(List<Book> booksToUpdate) async {
    final storage = ref.read(storageServiceProvider);
    for (final book in booksToUpdate) {
      await storage.saveBook(book);
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteBook(String id) async {
    final storage = ref.read(storageServiceProvider);
    await storage.deleteBook(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateStatus(
    String id,
    ReadingStatus newStatus, {
    DateTime? startDate,
    DateTime? finishDate,
  }) async {
    final current = state.value;
    if (current == null) return;

    final index = current.indexWhere((b) => b.id == id);
    if (index == -1) return;

    final existing = current[index];
    final updated = existing.copyWith(
      status: newStatus,
      startDate: startDate ?? existing.startDate ?? (newStatus == ReadingStatus.reading ? DateTime.now() : null),
      finishDate: finishDate ?? (newStatus == ReadingStatus.finished ? DateTime.now() : null),
    );

    await updateBook(updated);
  }
}
