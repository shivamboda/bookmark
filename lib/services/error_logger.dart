import 'package:flutter/foundation.dart';

/// Single logged application error for on-device diagnostics.
class AppErrorEntry {
  final DateTime timestamp;
  final String message;
  final String stackPreview;

  const AppErrorEntry({
    required this.timestamp,
    required this.message,
    required this.stackPreview,
  });
}

/// Global in-memory error recorder for the Diagnostics screen.
/// Retains the last 5 uncaught errors so users can report issues directly.
class AppErrorLogger {
  AppErrorLogger._();

  static const int maxErrors = 5;
  static final List<AppErrorEntry> _recentErrors = [];

  static List<AppErrorEntry> get recentErrors => List.unmodifiable(_recentErrors);

  static void recordError(Object error, StackTrace? stack, {String? context}) {
    final prefix = context != null ? '[$context] ' : '';
    final msg = '$prefix$error';

    final stackLines = (stack?.toString() ?? '')
        .split('\n')
        .where((l) =>
            l.trim().isNotEmpty &&
            !l.contains('dart-sdk') &&
            !l.contains('package:stack_trace'))
        .take(2)
        .map((l) => l.trim())
        .join(' \n');

    final entry = AppErrorEntry(
      timestamp: DateTime.now(),
      message: msg.length > 250 ? '${msg.substring(0, 250)}...' : msg,
      stackPreview: stackLines.isNotEmpty ? stackLines : 'No stack frame available',
    );

    _recentErrors.insert(0, entry);
    if (_recentErrors.length > maxErrors) {
      _recentErrors.removeLast();
    }
  }

  @visibleForTesting
  static void clearForTest() {
    _recentErrors.clear();
  }
}
