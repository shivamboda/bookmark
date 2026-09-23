import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/providers.dart';
import 'core/theme/app_theme.dart';
import 'doodles/doodle_gallery_screen.dart';
import 'features/library/screens/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize decoupled Hive CE storage
  await globalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(globalStorageService),
      ],
      child: const BookmarkApp(),
    ),
  );
}

/// Root Application Widget styled with the signature Poppy Blush theme
class BookmarkApp extends ConsumerWidget {
  const BookmarkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Bookmark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(mode: themeMode),
      home: const MainContainerScreen(),
    );
  }
}

/// Container that seamlessly switches between the Library and the Doodle Showcase
class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  bool _showDoodleGallery = false;

  @override
  Widget build(BuildContext context) {
    if (_showDoodleGallery) {
      return DoodleGalleryScreen(
        onBackToJournal: () => setState(() => _showDoodleGallery = false),
      );
    }

    return LibraryScreen(
      onOpenDoodleGallery: () => setState(() => _showDoodleGallery = true),
    );
  }
}
