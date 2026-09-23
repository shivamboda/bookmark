import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../services/storage_service.dart';
import '../theme/palette.dart';

/// Provider for the singleton StorageService instance.
/// Overridden in main() after initialization, or in tests with an in-memory mock.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized before use.');
});

/// Manages active floral theme mode and persists choice to storage.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, FloralThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<FloralThemeMode> {
  @override
  FloralThemeMode build() {
    _loadTheme();
    return FloralThemeMode.poppyBlush;
  }

  Future<void> _loadTheme() async {
    final storage = ref.read(storageServiceProvider);
    final saved = await storage.getSetting('theme_mode', defaultValue: 'poppyBlush');
    final match = FloralThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => FloralThemeMode.poppyBlush,
    );
    state = match;
  }

  Future<void> setTheme(FloralThemeMode mode) async {
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
    final storage = ref.read(storageServiceProvider);
    final saved = await storage.getSetting('yearly_goal');
    if (saved is int) {
      state = saved;
    }
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
