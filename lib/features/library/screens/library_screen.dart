import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/floral_rating_bar.dart';
import '../../../core/widgets/frosted_glass.dart';
import '../../../core/state/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../doodles/daisy_doodle.dart';
import '../../../doodles/leaf_sprig_doodle.dart';
import '../../../doodles/poppy_doodle.dart';
import '../../../doodles/sketch_underline.dart';
import '../../../doodles/tulip_doodle.dart';
import '../../../models/book.dart';
import '../widgets/book_grid_item.dart';
import '../widgets/book_list_card.dart';
import '../widgets/floral_bottom_nav.dart';
import '../widgets/library_empty_state.dart';
import '../widgets/stats_dashboard_view.dart';
import '../../../doodles/bookmark_ribbon_doodle.dart';
import '../../../doodles/acorn_doodle.dart';
import '../../../doodles/maple_leaf_doodle.dart';
import '../../../doodles/mushroom_doodle.dart';

import 'book_detail_screen.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../services/backup_service.dart';
import '../../../services/error_logger.dart';
import '../../../services/storage_service.dart';
import '../../../services/backup_transport.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'add_edit_book_screen.dart';
import 'book_search_screen.dart';

/// Status filter options for books displayed in the Library screen.
enum LibraryStatusFilter {
  all('All'),
  reading('Reading'),
  finished('Finished'),
  paused('Paused/DNF');

  final String label;
  const LibraryStatusFilter(this.label);
}

/// Sorting options for the user's reading journal shelf.
enum LibrarySortOption {
  dateFinished('Date Finished'),
  dateAdded('Date Added'),
  rating('Rating'),
  title('Title'),
  author('Author');

  final String label;
  const LibrarySortOption(this.label);
}

/// Step 4a: Handcrafted Botanical Library Screen.
class LibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenDoodleGallery;

  const LibraryScreen({
    super.key,
    this.onOpenDoodleGallery,
  });

  /// Visible for testing diagnostics
  @visibleForTesting
  static int get resumeCount => _LibraryScreenState._resumeCount;

  @visibleForTesting
  static void resetResumeDiagnosticsForTest() {
    _LibraryScreenState._resumeCount = 0;
    _LibraryScreenState._lastResumeTime = null;
    _LibraryScreenState._lastPauseTime = null;
  }

  @visibleForTesting
  static void setLastPauseTimeForTest(DateTime time) {
    _LibraryScreenState._lastPauseTime = time;
  }

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with WidgetsBindingObserver {
  // Lifecycle & iOS Touch Unfreeze Diagnostics
  static int _resumeCount = 0;
  static DateTime? _lastResumeTime;
  static DateTime? _lastPauseTime;


  bool _isGridView = false;
  LibraryStatusFilter _activeStatusFilter = LibraryStatusFilter.all;
  String? _selectedGenre;
  LibrarySortOption _sortOption = LibrarySortOption.dateAdded;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

  bool _isSelectionMode = false;
  bool _isUndoSnackBarActive = false;
  final Set<String> _selectedBookIds = <String>{};

  void _enterSelectionMode(String bookId) {
    setState(() {
      _isSelectionMode = true;
      _selectedBookIds.clear();
      _selectedBookIds.add(bookId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookIds.clear();
    });
  }

  void _toggleSelection(String bookId) {
    setState(() {
      if (_selectedBookIds.contains(bookId)) {
        _selectedBookIds.remove(bookId);
      } else {
        _selectedBookIds.add(bookId);
      }
    });
  }

  void _selectAll(List<Book> books) {
    setState(() {
      _selectedBookIds.addAll(books.map((b) => b.id));
    });
  }

  void _onLibrarySearchChanged(String val) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
      }
    });
  }

  void _clearLibrarySearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _openOnlineSearch(BuildContext context, String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSearchScreen(
          initialQuery: query,
          defaultStatus: _activeStatusFilter == LibraryStatusFilter.reading
              ? ReadingStatus.reading
              : ReadingStatus.wantToRead,
        ),
      ),
    );
  }

  int _currentNavIndex = 0;
  bool _isBackupBannerDismissed = false;
  DateTime? _lastBackupDate;
  bool _isStoragePersisted = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lastPauseTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }


  Widget _buildErrorDiagnosticsSection() {
    final errors = AppErrorLogger.recentErrors;
    final timeFormat = DateFormat('HH:mm:ss');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              errors.isEmpty ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
              size: 16,
              color: errors.isEmpty ? FloralPalette.sageGreenDark : FloralPalette.deepRose,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recent errors (${errors.length}):',
                key: const ValueKey('recent_errors_diagnostics_title'),
                style: JournalTypography.bodySmall(
                  color: FloralPalette.mutedCharcoal,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (errors.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              'No recent errors detected (clean session)',
              key: const ValueKey('recent_errors_empty_text'),
              style: JournalTypography.bodySmall(
                color: FloralPalette.mutedCharcoal.withValues(alpha: 0.8),
              ),
            ),
          )
        else
          ...errors.map((e) => Container(
                key: const ValueKey('recent_error_entry_container'),
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FloralPalette.petalWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FloralPalette.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[${timeFormat.format(e.timestamp)}] ${e.message}',
                      key: const ValueKey('recent_error_entry_msg'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF8B2500),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (e.stackPreview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.stackPreview,
                        key: const ValueKey('recent_error_entry_stack'),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: FloralPalette.mutedCharcoal,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
      ],
    );
  }

  String _generateDiagnosticsReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Bookmark Diagnostics Report ===');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Platform: ${kIsWeb ? "Web/PWA" : defaultTargetPlatform.name}');
    buffer.writeln('Theme: ${FloralPalette.isDark ? "Autumn Night (Dark)" : "Autumn Day (Light)"}');
    buffer.writeln('Storage Persisted: $_isStoragePersisted');
    buffer.writeln('Resume Events: $_resumeCount (last: ${_formatLastResumeTime()})');

    final errors = AppErrorLogger.recentErrors;
    buffer.writeln('Recent Errors (${errors.length}):');
    if (errors.isEmpty) {
      buffer.writeln('  No unhandled errors recorded (clean session).');
    } else {
      for (final e in errors) {
        buffer.writeln('  [${e.timestamp.toIso8601String()}] ${e.message}');
        if (e.stackPreview.isNotEmpty) buffer.writeln('    Stack: ${e.stackPreview}');
      }
    }
    return buffer.toString();
  }

  void _copyDiagnostics(BuildContext context) {
    final report = _generateDiagnosticsReport();
    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Diagnostics report copied to clipboard ~',
          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal),
        ),
        backgroundColor: FloralPalette.softIvory,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: FloralPalette.cardBorder),
        ),
      ),
    );
  }

  void _showReportProblemDialog(BuildContext context) {
    final report = _generateDiagnosticsReport();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FloralPalette.softIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: FloralPalette.deepRose, size: 22),
            const SizedBox(width: 8),
            Text(
              'Report a Problem',
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you are experiencing unexpected behavior or glitches, you can copy the diagnostic details below and send them to support.',
              style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
            ),
            const SizedBox(height: 12),
            Container(
              height: 140,
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FloralPalette.petalWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FloralPalette.cardBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  report,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: FloralPalette.mutedCharcoal),
            ),
          ),
          ElevatedButton.icon(
            key: const ValueKey('dialog_copy_diagnostics_btn'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _copyDiagnostics(context);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Diagnostics'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAppResume() {
    final now = DateTime.now();
    final wasLongSuspension = _lastPauseTime != null &&
        now.difference(_lastPauseTime!).inMinutes >= 5;

    if (mounted) {
      setState(() {
        _resumeCount++;
        _lastResumeTime = now;
      });
    } else {
      _resumeCount++;
      _lastResumeTime = now;
    }

    // 1. Reset stale pointer state and sweep stuck gesture arena members
    // WebKit often terminates touch sequences without touchcancel when backgrounded
    for (int i = 0; i <= 20; i++) {
      try {
        GestureBinding.instance.cancelPointer(i);
        GestureBinding.instance.gestureArena.sweep(i);
      } catch (_) {}
    }

    // 2. Safely request visual update to wake up WebKit compositor
    try {
      WidgetsBinding.instance.ensureVisualUpdate();
    } catch (_) {}

    // 3. Lightweight recovery after long background (> 5 minutes)
    // Pops modal sheets/dialogs if holding pointer traps, unless actively editing a book form
    if (wasLongSuspension && !AddEditBookScreen.isFormActive) {
      if (mounted && context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst || route is! PopupRoute);
      }
      if (_isSelectionMode) {
        _exitSelectionMode();
      }
    }
  }

  String _formatLastResumeTime() {
    if (_lastResumeTime == null) return 'never';
    final diff = DateTime.now().difference(_lastResumeTime!);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes <= 1) return '1 minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  Future<void> _loadSettings() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final savedGrid = await storage.getSetting('library_is_grid_view');
      final savedSort = await storage.getSetting('library_sort_option');

      final savedBackup = await storage.getSetting('last_backup_date');
      final persisted = await storage.getSetting('storage_persisted');

      if (mounted) {
        setState(() {
          if (savedGrid is bool) {
            _isGridView = savedGrid;
          }
          if (savedSort is String) {
            _sortOption = LibrarySortOption.values.firstWhere(
              (o) => o.name == savedSort,
              orElse: () => LibrarySortOption.dateAdded,
            );
          }
          if (savedBackup is String) {
            _lastBackupDate = DateTime.tryParse(savedBackup);
          }
          if (persisted is bool) {
            _isStoragePersisted = persisted;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading library settings: $e');
    }
  }

  Future<void> _toggleViewMode() async {
    final newMode = !_isGridView;
    setState(() => _isGridView = newMode);
    try {
      await ref.read(storageServiceProvider).setSetting('library_is_grid_view', newMode);
    } catch (e) {
      debugPrint('Failed to save grid view setting: $e');
    }
  }

  Future<void> _setSortOption(LibrarySortOption option) async {
    setState(() => _sortOption = option);
    try {
      await ref.read(storageServiceProvider).setSetting('library_sort_option', option.name);
    } catch (e) {
      debugPrint('Failed to save sort option setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: FloralPalette.petalWhite,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildLibraryTab(context, booksAsync),
                _buildWishlistTab(context, booksAsync),
                _buildStatsTab(context, booksAsync),
                _buildSettingsTab(context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: FloralBottomNav(
        currentIndex: _currentNavIndex,
        onTabSelected: (index) {
          if (_isSelectionMode) {
            _exitSelectionMode();
          }
          setState(() => _currentNavIndex = index);
        },
      ),
      floatingActionButton: (!_isSelectionMode && !_isUndoSnackBarActive && (_currentNavIndex == 0 || _currentNavIndex == 1))
          ? FrostedFloralFab(
              fabKey: const ValueKey('add_book_fab'),
              tooltip: 'Add Book',
              onPressed: () => _openAddBookScreen(context),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
    );
  }


  bool _shouldShowBackupBanner(List<Book> books) {
    if (_isBackupBannerDismissed) return false;
    if (books.isEmpty) return false;
    if (_lastBackupDate == null) return true;
    final days = DateTime.now().difference(_lastBackupDate!).inDays;
    return days > 30;
  }

  Widget _buildBackupReminderBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FloralPalette.bannerBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: FloralPalette.buttercupGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gentle backup reminder ~',
                  style: JournalTypography.handwriting(color: FloralPalette.warmCharcoal).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _lastBackupDate == null
                      ? "You have books in your library and haven't backed up yet."
                      : "It has been over 30 days since your last library backup.",
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: () => setState(() => _currentNavIndex = 3),
            style: TextButton.styleFrom(
              foregroundColor: FloralPalette.deepRose,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(40, 36),
            ),
            child: const Text('Back Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: FloralPalette.mutedCharcoal,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Dismiss reminder',
            onPressed: () => setState(() => _isBackupBannerDismissed = true),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStoragePersistence() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final granted = await storage.requestPersistentStorage();
      await storage.setSetting('storage_persisted', granted);
      if (mounted) {
        setState(() => _isStoragePersisted = granted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Storage protection granted! Your library is safeguarded.'
                  : 'Storage protection was not granted. Please back up your library regularly.',
            ),
            backgroundColor: granted ? FloralPalette.sageGreenDark : FloralPalette.deepRose,
          ),
        );
      }
    } catch (e) {
      debugPrint('Persistence request error: $e');
    }
  }

  String _formatLastBackup() {
    if (_lastBackupDate == null) return 'Never';
    return DateFormat.yMMMd().add_jm().format(_lastBackupDate!);
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final books = await storage.getAllBooks();
      final jsonString = await BackupService.exportLibraryJson(storage);

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'bookmark_backup_$dateStr.json';

      final canShare = isWebShareSupported();

      if (!context.mounted) return;

      if (canShare) {
        // Offer choice between Web Share and direct download
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) {
            return SafeArea(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FrostedGlassHeader(
                      borderRadius: 24,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: FloralPalette.latte,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Export Library Backup',
                              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to export ${books.length} books with all quotes, notes, and covers.',
                              style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      color: FloralPalette.softIvory,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF9EAE1),
                              child: Icon(Icons.share_rounded, color: FloralPalette.deepRose),
                            ),
                            title: const Text('Share Backup File'),
                            subtitle: const Text('Send via AirDrop, Messages, Drive, or Email'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await BackupService.downloadOrShareBackup(
                                jsonContent: jsonString,
                                customFileName: fileName,
                                preferShare: true,
                              );
                              _updateBackupState();
                            },
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEBF3ED),
                              child: Icon(Icons.file_download_rounded, color: FloralPalette.sageGreenDark),
                            ),
                            title: const Text('Download Backup JSON'),
                            subtitle: const Text('Save to your device Downloads folder'),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await BackupService.downloadOrShareBackup(
                                jsonContent: jsonString,
                                customFileName: fileName,
                                preferShare: false,
                              );
                              _updateBackupState();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
      } else {
        // Direct download
        await BackupService.downloadOrShareBackup(
          jsonContent: jsonString,
          customFileName: fileName,
          preferShare: false,
        );
        _updateBackupState();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Library backup downloaded! (${books.length} books exported)'),
              backgroundColor: FloralPalette.sageGreenDark,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  void _updateBackupState() {
    setState(() {
      _lastBackupDate = DateTime.now();
      _isBackupBannerDismissed = true;
    });
  }

  Future<void> _handleImport(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrostedGlassHeader(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: FloralPalette.latte,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Restore Library', style: JournalTypography.headingSmall()),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how you would like to restore your Bookmark library:',
                        style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: FloralPalette.petalWhite,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('restore_file_button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FloralPalette.deepRose,
                        foregroundColor: FloralPalette.softIvory,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.file_open_rounded, size: 20),
                      label: const Text('Select Backup File (.json)', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _pickAndProcessFile(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('restore_paste_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FloralPalette.deepRose,
                        side: const BorderSide(color: FloralPalette.blushPink),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.content_paste_rounded, size: 20),
                      label: const Text('Paste Backup JSON Text', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showPasteJsonDialog(context);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndProcessFile(BuildContext context) async {
    try {
      final fileBytes = await pickBackupFilePlatform();
      if (fileBytes == null || fileBytes.isEmpty) return;

      final jsonContent = utf8.decode(fileBytes, allowMalformed: true);
      if (!context.mounted) return;
      _processJsonContent(context, jsonContent);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error reading backup file: $e');
      }
    }
  }

  void _showPasteJsonDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        backgroundColor: FloralPalette.petalWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Paste Backup JSON', style: JournalTypography.headingSmall()),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your exported Bookmark JSON text below:',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{"metadata": {"format_version": 1, ...}}',
                  hintStyle: TextStyle(fontSize: 12, color: FloralPalette.mutedCharcoal.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: FloralPalette.softIvory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: FloralPalette.blushPink),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
            ),
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(dlgContext).pop();
              if (text.isNotEmpty) {
                _processJsonContent(context, text);
              }
            },
            child: const Text('Verify & Restore'),
          ),
        ],
      ),
    );
  }

  void _processJsonContent(BuildContext context, String rawJson) {
    final cleanJson = rawJson.trim().replaceFirst('\uFEFF', '');
    final validation = BackupService.validateBackupJson(cleanJson);

    if (!context.mounted) return;

    if (!validation.isValid) {
      _showErrorDialog(
        context,
        validation.errorMessage ?? 'The selected file is not a valid Bookmark backup.',
      );
      return;
    }

    // Show summary and choices dialog (Merge vs Replace)
    _showImportOptionsModal(context, validation);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: FloralPalette.deepRose),
            const SizedBox(width: 8),
            Text('Backup Notice', style: JournalTypography.headingSmall()),
          ],
        ),
        content: Text(message, style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: FloralPalette.deepRose)),
          ),
        ],
      ),
    );
  }

  void _showImportOptionsModal(BuildContext context, BackupValidationResult validation) {
    final storage = ref.read(storageServiceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FloralPalette.softIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D7C8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Restore Library Backup',
                  style: JournalTypography.headingMedium(color: FloralPalette.warmCharcoal),
                ),
                const SizedBox(height: 6),
                Text(
                  'Backup contents:',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FloralPalette.softIvory,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FloralPalette.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${validation.bookCount} books in backup', style: JournalTypography.bodySmall()),
                      const SizedBox(height: 4),
                      Text('• ${validation.quotesCount} favorite quotes', style: JournalTypography.bodySmall()),
                      const SizedBox(height: 4),
                      Text('• ${validation.coversCount} cached cover images', style: JournalTypography.bodySmall()),
                      if (validation.readingGoal != null) ...[
                        const SizedBox(height: 4),
                        Text('• Reading goal: ${validation.readingGoal} books', style: JournalTypography.bodySmall()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose how you want to restore:',
                  style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Option 1: MERGE
                InkWell(
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _executeImport(context, storage, validation.data!, merge: true);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: FloralPalette.sageGreenDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.merge_type_rounded, color: FloralPalette.sageGreenDark, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Merge with Existing Library',
                                style: JournalTypography.headingSmall(color: FloralPalette.sageGreenDark).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Adds new books and updates older ones. Duplicate titles with different IDs are safely skipped.',
                                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: REPLACE
                InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmReplace(context, storage, validation.data!);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: FloralPalette.deepRose),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: FloralPalette.deepRose, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Replace Entire Library',
                                style: JournalTypography.headingSmall(color: FloralPalette.deepRose).copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Wipes existing books and restores this backup completely, including covers, goal, and settings.',
                                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReplace(BuildContext context, StorageService storage, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: FloralPalette.deepRose),
            const SizedBox(width: 8),
            Text('Confirm Replace', style: JournalTypography.headingSmall()),
          ],
        ),
        content: Text(
          'Are you sure you want to replace your entire library?\n\nExisting books, quotes, and notes not present in this backup will be permanently removed.',
          style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _executeImport(context, storage, data, merge: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Replace Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeImport(
    BuildContext context,
    StorageService storage,
    Map<String, dynamic> data, {
    required bool merge,
  }) async {
    try {
      final summary = await BackupService.performImport(storage, data, merge: merge);

      ref.invalidate(booksProvider);
      ref.invalidate(yearlyGoalProvider);

      if (mounted) {
        setState(() {
          _lastBackupDate = DateTime.now();
          _isBackupBannerDismissed = true;
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary.toUserMessage()),
            backgroundColor: FloralPalette.sageGreenDark,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Import failed: $e\n\nYour existing library was left unchanged.');
      }
    }
  }

  // ==========================================
  // TAB 0: LIBRARY SCREEN
  // ==========================================
  Widget _buildLibraryTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Stack(
      children: [
        // Brown bookmark ribbon accent peeking gracefully from top edge
        const Positioned(
          top: 0,
          right: 78,
          child: IgnorePointer(
            child: BookmarkRibbonDoodle(
              width: 14,
              height: 32,
            ),
          ),
        ),

        // Full approved botanical poppy positioned fully inside the screen
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: PoppyDoodle(
              size: 72,
              showStem: false,
              petalColor: FloralPalette.rosePetal,
            ),
          ),
        ),

        // Floating autumn maple leaf drifting gently near the header
        const Positioned(
          top: 8,
          right: 98,
          child: IgnorePointer(
            child: MapleLeafDoodle(
              size: 28,
              color: FloralPalette.rosePetal,
              angle: -0.25,
            ),
          ),
        ),

        Column(
          children: [
            // Top App Header or Bulk Selection Header
            if (_isSelectionMode)
              _buildSelectionHeader(context, booksAsync.value ?? [])
            else ...[
              _buildHeader(context),
              if (_shouldShowBackupBanner(booksAsync.value ?? []))
                _buildBackupReminderBanner(context),
              _buildControlsBar(booksAsync.value ?? []),
            ],

            // Book Collection / Empty State
            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: FloralPalette.deepRose,
                    strokeWidth: 2.5,
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load your library: $error',
                      style: JournalTypography.bodySmall(color: Colors.red.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (allBooks) {
                  if (allBooks.isEmpty) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                      child: LibraryEmptyState(
                        onAddBook: () => _openAddBookScreen(context, defaultStatus: ReadingStatus.reading),
                      ),
                    );
                  }

                  final books = _filterAndSortBooks(allBooks);

                  if (books.isEmpty) {
                    return _buildNoMatchesState(allBooks);
                  }

                  if (_isGridView) {
                    return GridView.builder(
                      key: const ValueKey('library_grid_view'),
                      padding: EdgeInsets.fromLTRB(18, 12, 18, _isSelectionMode ? 190 : 140),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.60,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return BookGridItem(
                          book: book,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedBookIds.contains(book.id),
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(book.id);
                            } else {
                              _onBookSelected(context, book);
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _enterSelectionMode(book.id);
                            } else {
                              _toggleSelection(book.id);
                            }
                          },
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    key: const ValueKey('library_list_view'),
                    padding: EdgeInsets.fromLTRB(18, 12, 18, _isSelectionMode ? 190 : 140),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookListCard(
                        book: book,
                        isSelectionMode: _isSelectionMode,
                        isSelected: _selectedBookIds.contains(book.id),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(book.id);
                          } else {
                            _onBookSelected(context, book);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(book.id);
                          } else {
                            _toggleSelection(book.id);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),

        // Floating Bulk Action Bar (Docked above bottom navigation)
        if (_isSelectionMode)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBulkActionBar(context, booksAsync.value ?? []),
          ),
      ],
    );
  }

  // ==========================================
  // TAB 1: WISHLIST SCREEN
  // ==========================================
  Widget _buildWishlistTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Stack(
      children: [
        // Tulip motif resting in top-right
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: TulipDoodle(
              size: 68,
              showStem: false,
              petalColor: FloralPalette.rosePetal,
            ),
          ),
        ),

        // Little autumn acorn resting by the wishlist header
        const Positioned(
          top: 14,
          right: 92,
          child: IgnorePointer(
            child: AcornDoodle(
              size: 26,
              angle: 0.2,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • WISHLIST',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wishlist',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
                            width: 115,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• future dreams to read',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JournalTypography.handwriting(
                            color: FloralPalette.cocoa,
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: FloralPalette.deepRose),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (allBooks) {
                  final wishlistBooks = allBooks
                      .where((b) => b.status == ReadingStatus.wantToRead)
                      .toList()
                    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

                  if (wishlistBooks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: LibraryEmptyState(
                          title: "Books you'd love to read someday live here ~",
                          subtitle: "add stories you dream of reading next",
                          buttonLabel: "Find a Book",
                          onAddBook: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BookSearchScreen(),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
                    itemCount: wishlistBooks.length,
                    itemBuilder: (context, index) {
                      return BookListCard(
                        book: wishlistBooks[index],
                        isWishlist: true,
                        onTap: () => _onBookSelected(context, wishlistBooks[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: STATS SCREEN
  // ==========================================
  Widget _buildStatsTab(BuildContext context, AsyncValue<List<Book>> booksAsync) {
    return Stack(
      children: [
        // Daisy motif in top-right
        const Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: DaisyDoodle(
              size: 68,
              showStem: false,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • READING STATS',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stats',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
                            width: 80,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• pages and memories',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JournalTypography.handwriting(
                            color: FloralPalette.mutedCharcoal,
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: booksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: FloralPalette.deepRose),
                ),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (allBooks) {
                  return StatsDashboardView(
                    books: allBooks,
                    onNavigateToTab: (index) {
                      setState(() => _currentNavIndex = index);
                    },
                    onOpenBook: (book) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(bookId: book.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: SETTINGS SCREEN
  // ==========================================
    Widget _buildThemeToggleCard(BuildContext context) {
    final activeMode = ref.watch(themeModeProvider);
    final isDark = activeMode == FloralThemeMode.midnightGarden;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FloralPalette.cardBorder),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: -2,
            right: 0,
            child: IgnorePointer(
              child: MushroomDoodle(
                size: 32,
                capColor: FloralPalette.rosePetal,
                angle: 0.15,
              ),
            ),
          ),
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: FloralPalette.blushPink.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  size: 20,
                  color: FloralPalette.deepRose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance', style: JournalTypography.headingSmall()),
                    const SizedBox(height: 2),
                    Text(
                      'Choose your reading journal mood',
                      style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  key: const ValueKey('theme_toggle_day'),
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(FloralThemeMode.poppyBlush),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: !isDark
                          ? FloralPalette.deepRose
                          : FloralPalette.petalWhite.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: !isDark ? FloralPalette.deepRose : FloralPalette.cardBorder,
                        width: !isDark ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.light_mode_rounded,
                          size: 16,
                          color: !isDark ? Colors.white : FloralPalette.warmCharcoal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Autumn Day',
                          style: JournalTypography.bodySmall(
                            color: !isDark ? Colors.white : FloralPalette.warmCharcoal,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  key: const ValueKey('theme_toggle_night'),
                  onTap: () => ref.read(themeModeProvider.notifier).setTheme(FloralThemeMode.midnightGarden),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FloralPalette.deepRose
                          : FloralPalette.petalWhite.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? FloralPalette.deepRose : FloralPalette.cardBorder,
                        width: isDark ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 16,
                          color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Autumn Night',
                          style: JournalTypography.bodySmall(
                            color: isDark ? Colors.white : FloralPalette.warmCharcoal,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
  }

  Widget _buildSettingsTab(BuildContext context) {
    final yearlyGoal = ref.watch(yearlyGoalProvider);
    final currentYear = DateTime.now().year;

    return Stack(
      children: [
        // Leaf sprig motif in top-right
        Positioned(
          top: 10,
          right: 14,
          child: IgnorePointer(
            child: LeafSprigDoodle(
              size: 58,
              color: FloralPalette.deepForestGreen,
            ),
          ),
        ),

        // Little woodland forest mushroom tucked near settings header
        const Positioned(
          top: 14,
          right: 82,
          child: IgnorePointer(
            child: MushroomDoodle(
              size: 28,
              angle: -0.15,
            ),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKMARK • SETTINGS',
                    style: JournalTypography.bodySmall(
                      color: FloralPalette.deepForestGreen,
                    ).copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: JournalTypography.headingLarge(
                              color: FloralPalette.warmCharcoal,
                            ).copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          const HandDrawnUnderline(
                            width: 115,
                            color: FloralPalette.deepRose,
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          '• personal preferences',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: JournalTypography.handwriting(
                            color: FloralPalette.cocoa,
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
                child: Column(
                  children: [
                    // Theme Mode Toggle (Autumn Day vs Autumn Night)
                    _buildThemeToggleCard(context),
                    const SizedBox(height: 16),

                    // Reading Goal Setting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FloralPalette.softIvory,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FloralPalette.cardBorder),
                        boxShadow: [FloralPalette.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Yearly Reading Goal', style: JournalTypography.headingSmall()),
                          const SizedBox(height: 4),
                          Text('Set your target number of books for $currentYear', style: JournalTypography.bodySmall()),
                          const SizedBox(height: 14),

                          if (yearlyGoal == null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'No goal set',
                                    style: JournalTypography.subheading(color: FloralPalette.unratedText),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(12),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FloralPalette.deepRose,
                                    foregroundColor: FloralPalette.softIvory,
                                    minimumSize: const Size(44, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('Set a goal for the year'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$yearlyGoal books',
                                  style: JournalTypography.headingMedium(color: FloralPalette.deepRose),
                                ),
                                Row(
                                  children: [
                                    // Minus button with guaranteed >= 44x44 hit area
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                        onPressed: () {
                                          if (yearlyGoal <= 1) {
                                            ref.read(yearlyGoalProvider.notifier).setGoal(null);
                                          } else {
                                            ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal - 1);
                                          }
                                        },
                                        tooltip: yearlyGoal <= 1 ? 'Clear goal' : 'Decrease goal',
                                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 26),
                                        color: FloralPalette.deepRose,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Plus button with guaranteed >= 44x44 hit area
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                        onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(yearlyGoal + 1),
                                        tooltip: 'Increase goal',
                                        icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
                                        color: FloralPalette.deepRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => ref.read(yearlyGoalProvider.notifier).setGoal(null),
                                style: TextButton.styleFrom(
                                  foregroundColor: FloralPalette.mutedCharcoal,
                                  minimumSize: const Size(44, 44),
                                ),
                                child: const Text('Clear Goal', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Storage Protection Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FloralPalette.softIvory,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FloralPalette.cardBorder),
                        boxShadow: [FloralPalette.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isStoragePersisted ? Icons.verified_user_rounded : Icons.shield_outlined,
                                color: _isStoragePersisted ? FloralPalette.sageGreenDark : FloralPalette.buttercupGold,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isStoragePersisted ? 'Storage: Protected' : 'Standard Device Storage',
                                  style: JournalTypography.headingSmall(
                                    color: _isStoragePersisted ? FloralPalette.sageGreenDark : FloralPalette.buttercupGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isStoragePersisted
                                ? 'Persistent browser storage is granted on this device. Your books will not be automatically purged by the browser.'
                                : 'Your library is stored on this device. Please back up regularly.',
                            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                          ),
                          if (!_isStoragePersisted) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _checkStoragePersistence,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Check / Request Protection'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FloralPalette.deepRose,
                                side: const BorderSide(color: FloralPalette.deepRose),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Divider(height: 1, thickness: 0.8, color: FloralPalette.cardBorder),
                          Material(
                            color: Colors.transparent,
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: const ValueKey('advanced_diagnostics_tile'),
                              maintainState: true,
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                              leading: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: FloralPalette.mutedCharcoal,
                              ),
                              title: Text(
                                'Advanced Diagnostics',
                                style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                'Developer and troubleshooting info',
                                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sync_rounded, size: 16, color: FloralPalette.mutedCharcoal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Resume events: $_resumeCount (last: ${_formatLastResumeTime()})',
                                        key: const ValueKey('resume_events_diagnostics_text'),
                                        style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Divider(height: 1, thickness: 0.8, color: FloralPalette.cardBorder),
                                const SizedBox(height: 10),
                                _buildErrorDiagnosticsSection(),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        key: const ValueKey('copy_diagnostics_button'),
                                        onPressed: () => _copyDiagnostics(context),
                                        icon: const Icon(Icons.copy_rounded, size: 14),
                                        label: const Text('Copy Diagnostics', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: FloralPalette.warmCharcoal,
                                          side: BorderSide(color: FloralPalette.cardBorder),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        key: const ValueKey('report_problem_button'),
                                        onPressed: () => _showReportProblemDialog(context),
                                        icon: const Icon(Icons.help_outline_rounded, size: 14),
                                        label: const Text('Report Problem', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: FloralPalette.deepRose,
                                          side: const BorderSide(color: FloralPalette.deepRose),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      ),
                    ),

                    const SizedBox(height: 16),




                    // Backup & Restore Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FloralPalette.softIvory,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FloralPalette.cardBorder),
                        boxShadow: [FloralPalette.cardShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('Library Backup & Restore', style: JournalTypography.headingSmall()),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: FloralPalette.blushPink.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'v1 JSON',
                                  style: JournalTypography.bodySmall(color: FloralPalette.deepRose).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last backup: ${_formatLastBackup()}',
                            style: JournalTypography.handwriting(color: FloralPalette.deepRose).copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Save a copy of all books, quotes, ratings, notes, and cover images to a single file. You can restore or transfer your library anytime.',
                            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  key: const ValueKey('export_library_button'),
                                  onPressed: () => _handleExport(context),
                                  icon: const Icon(Icons.file_download_outlined, size: 18),
                                  label: const Text('Export Library'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: FloralPalette.deepRose,
                                    foregroundColor: FloralPalette.softIvory,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const ValueKey('import_library_button'),
                                  onPressed: () => _handleImport(context),
                                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                                  label: const Text('Restore Library'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FloralPalette.sageGreenDark,
                                    side: BorderSide(color: FloralPalette.sageGreenDark),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    ),

                    // Developer Doodle Showcase (strictly kDebugMode, no emoji)
                    if (kDebugMode && widget.onOpenDoodleGallery != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: widget.onOpenDoodleGallery,
                        icon: const Icon(Icons.palette_outlined, size: 20),
                        label: const Text('Open Botanical Doodle Sketchbook'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FloralPalette.deepRose,
                          foregroundColor: FloralPalette.softIvory,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Header with Fraunces title, hand-drawn underline, and romantic journal label
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOOKMARK • READING JOURNAL',
            style: JournalTypography.bodySmall(
              color: FloralPalette.deepForestGreen,
            ).copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: JournalTypography.headingLarge(
                      color: FloralPalette.warmCharcoal,
                    ).copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 2),
                  const HandDrawnUnderline(
                    width: 105,
                    color: FloralPalette.deepRose,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '• quiet garden of stories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: JournalTypography.handwriting(
                    color: FloralPalette.cocoa,
                  ).copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Friendly empty state when search or filters return 0 results
  Widget _buildNoMatchesState(List<Book> allBooks) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final globalMatches = allBooks.where((b) {
        final titleMatch = b.title.toLowerCase().contains(query);
        final authorMatch = b.authors.any((a) => a.toLowerCase().contains(query));
        return titleMatch || authorMatch;
      }).toList();

      if (globalMatches.isEmpty) {
        // Zero matches anywhere in library -> Offer online search fallback card
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              decoration: BoxDecoration(
                color: FloralPalette.softIvory,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                boxShadow: [FloralPalette.cardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TulipDoodle(size: 56, showStem: false, petalColor: FloralPalette.rosePetal),
                  const SizedBox(height: 14),
                  Text(
                    'Nothing on your shelf matches "$_searchQuery".',
                    textAlign: TextAlign.center,
                    style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Would you like to search for "$_searchQuery" online?',
                    textAlign: TextAlign.center,
                    style: JournalTypography.body(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    key: const ValueKey('search_online_fallback_btn'),
                    onPressed: () => _openOnlineSearch(context, _searchQuery),
                    icon: const Icon(Icons.travel_explore_rounded, size: 18),
                    label: Text('Search online for "$_searchQuery"'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FloralPalette.deepRose,
                      foregroundColor: FloralPalette.softIvory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    key: const ValueKey('clear_filters_btn'),
                    onPressed: _clearLibrarySearch,
                    child: Text(
                      'Clear search',
                      style: JournalTypography.bodySmall(color: FloralPalette.cocoa),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Matches exist in library, but active status/genre filters are hiding them
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              decoration: BoxDecoration(
                color: FloralPalette.softIvory,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                boxShadow: [FloralPalette.cardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TulipDoodle(size: 56, showStem: false, petalColor: FloralPalette.sageGreenDark),
                  const SizedBox(height: 14),
                  Text(
                    'Filters are hiding matches for "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try clearing your filters to see ${globalMatches.length} matching ${globalMatches.length == 1 ? "book" : "books"} on your shelf ~',
                    textAlign: TextAlign.center,
                    style: JournalTypography.body(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    key: const ValueKey('clear_filters_btn'),
                    onPressed: () {
                      setState(() {
                        _activeStatusFilter = LibraryStatusFilter.all;
                        _selectedGenre = null;
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('Clear Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FloralPalette.deepRose,
                      foregroundColor: FloralPalette.softIvory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Default empty filter state (no search query typed)
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TulipDoodle(size: 64, showStem: false, petalColor: FloralPalette.rosePetal),
            const SizedBox(height: 16),
            Text(
              'Nothing matches that yet ~',
              textAlign: TextAlign.center,
              style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'try adjusting your search, filters, or shelves ~',
              textAlign: TextAlign.center,
              style: JournalTypography.handwriting(color: FloralPalette.cocoa).copyWith(fontSize: 15),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              key: const ValueKey('clear_filters_btn'),
              onPressed: () {
                setState(() {
                  _activeStatusFilter = LibraryStatusFilter.all;
                  _selectedGenre = null;
                  _searchDebounceTimer?.cancel();
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Set<String> _canonicalGenres = {
    'Fantasy', 'Romance', 'Mystery', 'Historical Fiction', 'Classic',
    'Sci-Fi', 'Non-fiction', 'Poetry', 'Thriller', 'Young Adult',
    'Mythology', 'Drama',
  };

  static bool _isCleanGenreTag(String g) {
    final trimmed = g.trim();
    if (trimmed.isEmpty) return false;
    if (_canonicalGenres.contains(trimmed)) return true;
    if (trimmed.contains(':') || trimmed.contains(',') || trimmed.contains('=') || trimmed.contains('/')) return false;
    if (trimmed.length > 20) return false;
    final lower = trimmed.toLowerCase();
    if (lower.contains('nyt') || lower.contains('bestseller') || lower.contains('print') || lower.contains('edition')) return false;
    if (lower.contains('fiction') && trimmed.contains(' ')) return false;
    return true;
  }

  /// Controls bar containing search field, status filter chips, genre dropdown, sort dropdown, and list/grid toggle
  Widget _buildControlsBar(List<Book> allBooks) {
    final availableGenres = allBooks
        .expand((b) => b.cleanGenres)
        .where(_isCleanGenreTag)
        .toSet()
        .toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Box for personal library (title & author)
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: FloralPalette.softIvory,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
              boxShadow: [FloralPalette.cardShadow],
            ),
            child: TextField(
              key: const ValueKey('library_search_input'),
              controller: _searchController,
              onChanged: _onLibrarySearchChanged,
              style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search shelf by title or author...',
                hintStyle: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 12.5),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: FloralPalette.cocoa),
                suffixIcon: (_searchQuery.isNotEmpty || _searchController.text.isNotEmpty)
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 16, color: FloralPalette.mutedCharcoal),
                        onPressed: _clearLibrarySearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Status Filter Chips (All, Reading, Finished, Paused/DNF)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: LibraryStatusFilter.values.map((filter) {
                final isSelected = _activeStatusFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    key: ValueKey('status_chip_${filter.name}'),
                    onTap: () => setState(() => _activeStatusFilter = filter),
                    borderRadius: BorderRadius.circular(14),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 36),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? FloralPalette.deepRose : FloralPalette.softIvory,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? FloralPalette.deepRose : FloralPalette.cardBorder,
                            width: 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: FloralPalette.deepRose.withValues(alpha: 0.22),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          filter.label,
                          style: JournalTypography.bodySmall(
                            color: isSelected ? Colors.white : FloralPalette.warmCharcoal,
                          ).copyWith(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Secondary Controls: Genre Filter, Sort Options, Grid/List Mode
          Row(
            children: [
              // Genre Filter Button / Dropdown
              PopupMenuButton<String>(
                key: const ValueKey('genre_filter_button'),
                initialValue: _selectedGenre ?? '',
                onSelected: (genre) {
                  setState(() {
                    _selectedGenre = (genre.isEmpty || genre == '__all__') ? null : genre;
                  });
                },
                color: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: '',
                      key: const ValueKey('genre_item_all'),
                      child: Row(
                        children: [
                          if (_selectedGenre == null) ...[
                            const Icon(Icons.check_rounded, size: 14, color: FloralPalette.deepRose),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            'All Genres',
                            style: JournalTypography.bodySmall(
                              color: _selectedGenre == null ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                            ).copyWith(fontWeight: _selectedGenre == null ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    ...availableGenres.map(
                      (g) => PopupMenuItem<String>(
                        value: g,
                        key: ValueKey('genre_item_$g'),
                        child: Row(
                          children: [
                            if (_selectedGenre == g) ...[
                              const Icon(Icons.check_rounded, size: 14, color: FloralPalette.deepRose),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              g,
                              style: JournalTypography.bodySmall(
                                color: _selectedGenre == g ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                              ).copyWith(fontWeight: _selectedGenre == g ? FontWeight.w700 : FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedGenre != null
                        ? FloralPalette.blushPink.withValues(alpha: 0.3)
                        : FloralPalette.softIvory,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGenre != null ? FloralPalette.deepRose : FloralPalette.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 15,
                        color: _selectedGenre != null ? FloralPalette.deepRose : FloralPalette.cocoa,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedGenre ?? 'All Genres',
                        style: JournalTypography.bodySmall(
                          color: _selectedGenre != null ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (_selectedGenre != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          key: const ValueKey('clear_genre_chip_btn'),
                          onTap: () => setState(() => _selectedGenre = null),
                          child: const Icon(Icons.close_rounded, size: 14, color: FloralPalette.deepRose),
                        ),
                      ] else ...[
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Sort Option Button / Dropdown
              PopupMenuButton<LibrarySortOption>(
                key: const ValueKey('sort_option_button'),
                initialValue: _sortOption,
                onSelected: (opt) => _setSortOption(opt),
                color: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                itemBuilder: (context) {
                  return LibrarySortOption.values.map(
                    (opt) => PopupMenuItem<LibrarySortOption>(
                      value: opt,
                      key: ValueKey('sort_item_${opt.name}'),
                      child: Row(
                        children: [
                          if (_sortOption == opt) ...[
                            const Icon(Icons.check_rounded, size: 14, color: FloralPalette.deepRose),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            opt.label,
                            style: JournalTypography.bodySmall(
                              color: _sortOption == opt ? FloralPalette.deepRose : FloralPalette.warmCharcoal,
                            ).copyWith(fontWeight: _sortOption == opt ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FloralPalette.softIvory,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded, size: 15, color: FloralPalette.cocoa),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption.label,
                        style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // List / Grid Mode Toggle Button (44px+ tap target)
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey('view_mode_toggle_btn'),
                  onTap: _toggleViewMode,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: FloralPalette.softIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
                    ),
                    child: Icon(
                      _isGridView ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                      color: FloralPalette.deepRose,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Book> _filterAndSortBooks(List<Book> allBooks) {
    // 1. Status Filter
    var filtered = allBooks.where((b) {
      switch (_activeStatusFilter) {
        case LibraryStatusFilter.all:
          return true;
        case LibraryStatusFilter.reading:
          return b.status == ReadingStatus.reading;
        case LibraryStatusFilter.finished:
          return b.status == ReadingStatus.finished;
        case LibraryStatusFilter.paused:
          return b.status == ReadingStatus.paused;
      }
    }).toList();

    // 2. Genre Filter
    if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
      filtered = filtered.where((b) => b.cleanGenres.contains(_selectedGenre)).toList();
    }

    // 3. Search Query (title and author)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((b) {
        final titleMatch = b.title.toLowerCase().contains(query);
        final authorMatch = b.authors.any((a) => a.toLowerCase().contains(query));
        return titleMatch || authorMatch;
      }).toList();
    }

    // 4. Sorting
    filtered.sort((a, b) {
      switch (_sortOption) {
        case LibrarySortOption.dateFinished:
          if (a.finishDate == null && b.finishDate == null) return b.dateAdded.compareTo(a.dateAdded);
          if (a.finishDate == null) return 1;
          if (b.finishDate == null) return -1;
          return b.finishDate!.compareTo(a.finishDate!);
        case LibrarySortOption.dateAdded:
          return b.dateAdded.compareTo(a.dateAdded);
        case LibrarySortOption.rating:
          final rA = a.rating ?? 0.0;
          final rB = b.rating ?? 0.0;
          final cmp = rB.compareTo(rA);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.author:
          final authA = (a.authors.firstOrNull ?? '').toLowerCase();
          final authB = (b.authors.firstOrNull ?? '').toLowerCase();
          final cmp = authA.compareTo(authB);
          if (cmp != 0) return cmp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  void _onBookSelected(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(bookId: book.id),
      ),
    );
  }

  void _openAddBookScreen(BuildContext context, {ReadingStatus? defaultStatus}) {
    final status = defaultStatus ??
        (_currentNavIndex == 1
            ? ReadingStatus.wantToRead
            : ReadingStatus.reading);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookSearchScreen(defaultStatus: status),
      ),
    );
  }

  // ==========================================
  // BULK SELECTION MODE WIDGETS & ACTIONS
  // ==========================================

  Widget _buildSelectionHeader(BuildContext context, List<Book> allBooks) {
    final filtered = _filterAndSortBooks(allBooks);
    final count = _selectedBookIds.length;

    return Container(
      key: const ValueKey('library_selection_header'),
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FloralPalette.softIvory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FloralPalette.cardBorder, width: 1.0),
        boxShadow: [FloralPalette.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: FloralPalette.deepRose.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: FloralPalette.deepRose, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            '$count selected',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal).copyWith(fontSize: 16),
          ),
          const Spacer(),
          // Select All button (min 44px tap target)
          TextButton(
            key: const ValueKey('select_all_button'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: FloralPalette.deepRose,
            ),
            onPressed: () => _selectAll(filtered),
            child: const Text('Select all', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
          const SizedBox(width: 4),
          // Cancel button (min 44px tap target)
          TextButton(
            key: const ValueKey('cancel_selection_button'),
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: FloralPalette.mutedCharcoal,
            ),
            onPressed: _exitSelectionMode,
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, List<Book> allBooks) {
    final count = _selectedBookIds.length;
    final bool hasSelection = count > 0;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(22),
      shadowColor: Colors.black26,
      color: FloralPalette.softIvory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: FloralPalette.softIvory,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FloralPalette.cardBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const ValueKey('bulk_set_year_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FloralPalette.kraftPaper,
                    foregroundColor: FloralPalette.warmCharcoal,
                    elevation: 0,
                    side: BorderSide(color: FloralPalette.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.event_outlined, size: 20, color: FloralPalette.deepRose),
                  label: const Text('Set year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  onPressed: hasSelection ? () => _showBulkSetYearFlow(context, allBooks) : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  key: const ValueKey('bulk_rate_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FloralPalette.kraftPaper,
                    foregroundColor: FloralPalette.warmCharcoal,
                    elevation: 0,
                    side: BorderSide(color: FloralPalette.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.star_rounded, size: 22, color: FloralPalette.buttercupGold),
                  label: const Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  onPressed: hasSelection ? () => _showBulkRateFlow(context, allBooks) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBulkSetYearFlow(BuildContext context, List<Book> allBooks) async {
    final selectedBooks = allBooks.where((b) => _selectedBookIds.contains(b.id)).toList();
    if (selectedBooks.isEmpty) return;

    final nonFinished = selectedBooks.where((b) => b.status != ReadingStatus.finished).toList();
    bool markNonFinishedAsFinished = false;

    // Check if any selected books are non-Finished
    if (nonFinished.isNotEmpty) {
      final shouldMark = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: FloralPalette.softIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: FloralPalette.cardBorder)),
          title: Text(
            'Mark as Finished?',
            style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
          ),
          content: Text(
            '${nonFinished.length} of the ${selectedBooks.length} selected books are not currently marked as Finished.\n\nWould you like to mark them as Finished now so an approximate read year can be set?',
            style: JournalTypography.body(color: FloralPalette.warmCharcoal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
            ),
            if (selectedBooks.length > nonFinished.length)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Only Finished (${selectedBooks.length - nonFinished.length})', style: TextStyle(color: FloralPalette.deepForestGreen)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FloralPalette.deepRose,
                foregroundColor: FloralPalette.softIvory,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Mark Finished & Continue'),
            ),
          ],
        ),
      );

      if (shouldMark == null) return;
      markNonFinishedAsFinished = shouldMark;
    }

    final booksToUpdate = markNonFinishedAsFinished
        ? selectedBooks
        : selectedBooks.where((b) => b.status == ReadingStatus.finished).toList();

    if (booksToUpdate.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No finished books were selected to update.')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final pickerResult = await showDialog<_YearPickerResult>(
      context: context,
      builder: (ctx) => _YearPickerDialog(bookCount: booksToUpdate.length),
    );

    if (pickerResult == null || !context.mounted) return;

    final String dateDescription;
    if (pickerResult.isYearUnknown) {
      dateDescription = 'Year unknown / read long ago';
    } else if (pickerResult.month != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      dateDescription = '${months[pickerResult.month! - 1]} ${pickerResult.year}';
    } else {
      dateDescription = '${pickerResult.year}';
    }

    final String confirmSummary = markNonFinishedAsFinished && nonFinished.isNotEmpty
        ? 'Mark ${nonFinished.length} books as Finished and set ${booksToUpdate.length} books to $dateDescription?'
        : 'Set ${booksToUpdate.length} books to $dateDescription?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FloralPalette.softIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: FloralPalette.cardBorder)),
        title: Text(
          'Confirm Bulk Update',
          style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
        ),
        content: Text(
          confirmSummary,
          style: JournalTypography.body(color: FloralPalette.warmCharcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Save previous state for Undo
    final previousStates = { for (final b in booksToUpdate) b.id: b };
    final updatedBooks = booksToUpdate.map((b) {
      if (pickerResult.isYearUnknown) {
        return b.copyWith(
          status: ReadingStatus.finished,
          clearFinishDate: true,
          finishDateIsApproximate: true,
          finishDateHasMonth: false,
        );
      } else if (pickerResult.month != null) {
        return b.copyWith(
          status: ReadingStatus.finished,
          finishDate: DateTime(pickerResult.year!, pickerResult.month!, 15),
          finishDateIsApproximate: true,
          finishDateHasMonth: true,
        );
      } else {
        return b.copyWith(
          status: ReadingStatus.finished,
          finishDate: DateTime(pickerResult.year!, 7, 2),
          finishDateIsApproximate: true,
          finishDateHasMonth: false,
        );
      }
    }).toList();

    await ref.read(booksProvider.notifier).bulkUpdateBooks(updatedBooks);
    _exitSelectionMode();

    if (context.mounted) {
      setState(() => _isUndoSnackBarActive = true);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Set ${updatedBooks.length} books to $dateDescription.',
            style: JournalTypography.body(color: const Color(0xFF2C2018)).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(milliseconds: 2800),
          persist: false,
          behavior: SnackBarBehavior.fixed,
          shape: const Border(
            top: BorderSide(color: Color(0xFFE2D6CB), width: 1.0),
          ),
          backgroundColor: const Color(0xFFFAF6F0),
          elevation: 3,
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFB85D19),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (mounted) setState(() => _isUndoSnackBarActive = false);
              await ref.read(booksProvider.notifier).bulkUpdateBooks(previousStates.values.toList());
            },
          ),
        ),
      );

      // Auto-dismiss after 2.8 seconds and restore FAB cleanly
      Timer(const Duration(milliseconds: 2900), () {
        if (mounted) {
          setState(() => _isUndoSnackBarActive = false);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    }
  }

  Future<void> _showBulkRateFlow(BuildContext context, List<Book> allBooks) async {
    final selectedBooks = allBooks.where((b) => _selectedBookIds.contains(b.id)).toList();
    if (selectedBooks.isEmpty) return;

    final pickerResult = await showDialog<_RatePickerResult>(
      context: context,
      builder: (ctx) => _RatePickerDialog(bookCount: selectedBooks.length),
    );

    if (pickerResult == null || !context.mounted) return;

    final String confirmSummary = pickerResult.clearRating
        ? 'Clear rating for ${selectedBooks.length} books?'
        : 'Rate ${selectedBooks.length} books ${pickerResult.rating!.toStringAsFixed(1)} stars?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FloralPalette.softIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: FloralPalette.cardBorder)),
        title: Text(
          'Confirm Bulk Rating',
          style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
        ),
        content: Text(
          confirmSummary,
          style: JournalTypography.body(color: FloralPalette.warmCharcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final previousStates = { for (final b in selectedBooks) b.id: b };
    final updatedBooks = selectedBooks.map((b) {
      if (pickerResult.clearRating) {
        return b.copyWith(clearRating: true);
      } else {
        return b.copyWith(rating: pickerResult.rating);
      }
    }).toList();

    await ref.read(booksProvider.notifier).bulkUpdateBooks(updatedBooks);
    _exitSelectionMode();

    if (context.mounted) {
      setState(() => _isUndoSnackBarActive = true);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickerResult.clearRating
                ? 'Cleared rating for ${updatedBooks.length} books.'
                : 'Rated ${updatedBooks.length} books ${pickerResult.rating!.toStringAsFixed(1)} stars.',
            style: JournalTypography.body(color: const Color(0xFF2C2018)).copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(milliseconds: 2800),
          persist: false,
          behavior: SnackBarBehavior.fixed,
          shape: const Border(
            top: BorderSide(color: Color(0xFFE2D6CB), width: 1.0),
          ),
          backgroundColor: const Color(0xFFFAF6F0),
          elevation: 3,
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFB85D19),
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (mounted) setState(() => _isUndoSnackBarActive = false);
              await ref.read(booksProvider.notifier).bulkUpdateBooks(previousStates.values.toList());
            },
          ),
        ),
      );

      // Auto-dismiss after 2.8 seconds and restore FAB cleanly
      Timer(const Duration(milliseconds: 2900), () {
        if (mounted) {
          setState(() => _isUndoSnackBarActive = false);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    }
  }
}


// ==========================================
// BULK SELECTION MODAL DIALOGS
// ==========================================

class _YearPickerResult {
  final int? year;
  final int? month;
  final bool isYearUnknown;

  const _YearPickerResult({
    this.year,
    this.month,
    required this.isYearUnknown,
  });
}

class _YearPickerDialog extends StatefulWidget {
  final int bookCount;

  const _YearPickerDialog({required this.bookCount});

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  bool _isYearUnknown = false;
  late int _selectedYear;
  int? _selectedMonth; // null = Year only

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(currentYear - 1950 + 1, (i) => currentYear - i);

    return AlertDialog(
      backgroundColor: FloralPalette.softIvory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: FloralPalette.cardBorder, width: 1.0),
      ),
      title: Text(
        'Set Read Year',
        style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the approximate completion year for ${widget.bookCount} selected ${widget.bookCount == 1 ? "book" : "books"}:',
              style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
            ),
            const SizedBox(height: 16),

            // Option 1: Approximate Year (and optional month)
            InkWell(
              onTap: () => setState(() => _isYearUnknown = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !_isYearUnknown ? FloralPalette.blushPink.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_isYearUnknown ? FloralPalette.deepRose : FloralPalette.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          !_isYearUnknown ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: !_isYearUnknown ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pick Year & Month',
                          style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (!_isYearUnknown) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Year dropdown
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                labelStyle: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: years.map((y) {
                                return DropdownMenuItem(value: y, child: Text('$y'));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedYear = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Optional Month dropdown
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: _selectedMonth,
                              decoration: InputDecoration(
                                labelText: 'Month (Optional)',
                                labelStyle: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All Year', style: TextStyle(fontStyle: FontStyle.italic)),
                                ),
                                ...List.generate(12, (index) {
                                  return DropdownMenuItem<int?>(
                                    value: index + 1,
                                    child: Text(_monthNames[index]),
                                  );
                                }),
                              ],
                              onChanged: (val) => setState(() => _selectedMonth = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Option 2: Year unknown / long ago
            InkWell(
              onTap: () => setState(() => _isYearUnknown = true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isYearUnknown ? FloralPalette.blushPink.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isYearUnknown ? FloralPalette.deepRose : FloralPalette.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isYearUnknown ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 18,
                      color: _isYearUnknown ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Year unknown / long ago',
                            style: JournalTypography.body(color: FloralPalette.warmCharcoal).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Marks as Finished with no date. Excluded from year stats but counted in lifetime totals.',
                            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: FloralPalette.deepRose,
            foregroundColor: FloralPalette.softIvory,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.of(context).pop(
              _YearPickerResult(
                year: _isYearUnknown ? null : _selectedYear,
                month: _isYearUnknown ? null : _selectedMonth,
                isYearUnknown: _isYearUnknown,
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _RatePickerResult {
  final double? rating;
  final bool clearRating;

  const _RatePickerResult({
    this.rating,
    this.clearRating = false,
  });
}

class _RatePickerDialog extends StatefulWidget {
  final int bookCount;

  const _RatePickerDialog({required this.bookCount});

  @override
  State<_RatePickerDialog> createState() => _RatePickerDialogState();
}

class _RatePickerDialogState extends State<_RatePickerDialog> {
  double? _rating = 4.0;
  bool _clearRating = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FloralPalette.softIvory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: FloralPalette.cardBorder, width: 1.0),
      ),
      title: Text(
        'Rate Selected Books',
        style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Apply a rating to ${widget.bookCount} selected ${widget.bookCount == 1 ? "book" : "books"}:',
            style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
          ),
          const SizedBox(height: 20),

          if (!_clearRating) ...[
            Center(
              child: FloralRatingBar(
                rating: _rating,
                blossomSize: 32,
                onRatingChanged: (newRating) {
                  setState(() {
                    _rating = newRating;
                    _clearRating = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _rating != null ? '${_rating!.toStringAsFixed(1)} Stars' : 'Unrated',
              style: JournalTypography.headingMedium(color: FloralPalette.buttercupGold).copyWith(fontSize: 20),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: FloralPalette.blushPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Rating will be cleared (Unrated)',
                style: JournalTypography.body(color: FloralPalette.deepRose).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],

          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _clearRating ? FloralPalette.deepRose : FloralPalette.mutedCharcoal,
              side: BorderSide(color: _clearRating ? FloralPalette.deepRose : FloralPalette.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(_clearRating ? Icons.check_rounded : Icons.clear_rounded, size: 16),
            label: Text(_clearRating ? 'Keep Rating Cleared' : 'Clear Rating'),
            onPressed: () {
              setState(() {
                _clearRating = !_clearRating;
                if (!_clearRating && _rating == null) {
                  _rating = 4.0;
                }
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: TextStyle(color: FloralPalette.mutedCharcoal)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: FloralPalette.deepRose,
            foregroundColor: FloralPalette.softIvory,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.of(context).pop(
              _RatePickerResult(
                rating: _clearRating ? null : _rating,
                clearRating: _clearRating,
              ),
            );
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
