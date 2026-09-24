import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../services/storage_service.dart';
import '../../../services/backup_transport.dart';

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

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isGridView = false;
  LibraryStatusFilter _activeStatusFilter = LibraryStatusFilter.all;
  String? _selectedGenre;
  LibrarySortOption _sortOption = LibrarySortOption.dateAdded;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounceTimer;

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
    _loadSettings();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
          setState(() => _currentNavIndex = index);
        },
      ),
      floatingActionButton: (_currentNavIndex == 0 || _currentNavIndex == 1)
          ? FloatingActionButton(
              key: const ValueKey('add_book_fab'),
              onPressed: () => _openAddBookScreen(context),
              backgroundColor: FloralPalette.deepRose,
              foregroundColor: FloralPalette.softIvory,
              elevation: 3,
              tooltip: 'Add Book',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          backgroundColor: FloralPalette.softIvory,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Library Backup',
                      style: JournalTypography.headingSmall(color: FloralPalette.warmCharcoal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ready to export ${books.length} books with all quotes, notes, and covers.',
                      style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
                    ),
                    const SizedBox(height: 20),
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
                      subtitle: const Text('Save file directly to your device downloads'),
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
            );
          },
        );
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
      backgroundColor: FloralPalette.petalWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Restore Library', style: JournalTypography.headingSmall()),
              const SizedBox(height: 6),
              Text(
                'Choose how you would like to restore your Bookmark library:',
                style: JournalTypography.bodySmall(color: FloralPalette.mutedCharcoal),
              ),
              const SizedBox(height: 20),
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

      setState(() {
        _lastBackupDate = DateTime.now();
        _isBackupBannerDismissed = true;
      });

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
            // Top App Header
            _buildHeader(context),

            // Backup reminder banner (dismissible, if >30 days or never backed up with books)
            if (_shouldShowBackupBanner(booksAsync.value ?? []))
              _buildBackupReminderBanner(context),

            // Filter Chips, Search & View Mode Toggle Bar
            _buildControlsBar(booksAsync.value ?? []),

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
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
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
                          onTap: () => _onBookSelected(context, book),
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    key: const ValueKey('library_list_view'),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 140),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return BookListCard(
                        book: book,
                        onTap: () => _onBookSelected(context, book),
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
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: FloralPalette.cocoa),
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
                        const Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
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
                      const Icon(Icons.swap_vert_rounded, size: 15, color: FloralPalette.cocoa),
                      const SizedBox(width: 4),
                      Text(
                        _sortOption.label,
                        style: JournalTypography.bodySmall(color: FloralPalette.warmCharcoal).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: FloralPalette.cocoa),
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
}
