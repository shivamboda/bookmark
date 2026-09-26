import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/state/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/palette.dart';
import 'doodles/doodle_gallery_screen.dart';
import 'services/error_logger.dart';
import 'features/library/screens/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Global uncaught error logging for Diagnostics screen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrorLogger.recordError(
      details.exception,
      details.stack,
      context: details.context?.toDescription(),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppErrorLogger.recordError(error, stack, context: 'Platform');
    return false;
  };

  // Initialize decoupled Hive CE storage
  await globalStorageService.init();

  // Request browser storage persistence and record the result
  try {
    final isPersisted = await globalStorageService.requestPersistentStorage();
    await globalStorageService.setSetting('storage_persisted', isPersisted);
  } catch (e) {
    debugPrint('Storage persistence check: \$e');
  }

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
    FloralPalette.currentMode = themeMode;

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

class _MainContainerScreenState extends State<MainContainerScreen>
    with WidgetsBindingObserver {
  bool _showDoodleGallery = false;
  final List<Timer> _stabilizationTimers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Standalone PWA cold-start viewport stabilization:
    // On iOS Safari standalone mode, WebKit often reports pre-settled viewport metrics during
    // initial layout. We schedule post-frame checks shortly after startup to force Flutter
    // to re-evaluate physicalSize and re-layout the tree once WebKit settles into full standalone geometry.
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stabilizeColdStartViewport();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _stabilizationTimers) {
      timer.cancel();
    }
    _stabilizationTimers.clear();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // If a text input has active focus, Flutter's framework (Scaffold/MediaQuery)
    // already automatically animates viewInsets and keeps the input visible.
    // Do NOT trigger an unnecessary top-level rebuild that could interfere with text input focus.
    if (mounted && FocusManager.instance.primaryFocus == null) {
      setState(() {});
    }
  }

  void _stabilizeColdStartViewport() {
    const delays = [
      Duration(milliseconds: 100),
      Duration(milliseconds: 300),
      Duration(milliseconds: 600),
      Duration(milliseconds: 1200),
      Duration(milliseconds: 2000),
    ];

    for (final delay in delays) {
      final timer = Timer(delay, () {
        if (!mounted) return;
        // Never trigger forced metrics changes if the user is already typing in a text field
        if (FocusManager.instance.primaryFocus != null) return;
        WidgetsBinding.instance.handleMetricsChanged();
        setState(() {});
      });
      _stabilizationTimers.add(timer);
    }
  }

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
