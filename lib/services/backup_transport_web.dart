import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation using Web Share API with Blob anchor download fallback.
Future<bool> saveOrShareBackupPlatform({
  required String jsonContent,
  required String fileName,
  bool preferShare = false,
}) async {
  final bytes = utf8.encode(jsonContent);

  if (preferShare) {
    try {
      final file = web.File(
        [bytes.toJS].toJS,
        fileName,
        web.FilePropertyBag(type: 'application/json'),
      );
      final shareData = web.ShareData(
        files: [file].toJS,
        title: 'Bookmark Library Backup',
        text: 'Backup of my reading journal from Bookmark',
      );
      if (web.window.navigator.canShare(shareData)) {
        await web.window.navigator.share(shareData).toDart;
        return true;
      }
    } catch (e) {
      debugPrint('Web Share declined or unavailable: ');
      // Fall through to download fallback
    }
  }

  // Blob anchor download fallback
  try {
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (e) {
    debugPrint('Web file download failed: ');
    return false;
  }
}

bool isWebShareSupported() {
  try {
    return true;
  } catch (_) {
    return false;
  }
}

/// Robust web file picker for JSON backups.
/// Designed specifically to avoid WebKit / iOS Safari file input dropouts:
/// 1. Kept in the DOM until file processing completes (not removed immediately on click).
/// 2. No window blur/focus cancel listener (which prematurely kills sessions on iOS).
/// 3. Standard and broad accept attribute including MIME types.
Future<Uint8List?> pickBackupFilePlatform() {
  final completer = Completer<Uint8List?>();

  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.json,application/json,text/json,text/plain,*/*'
    ..style.display = 'none';

  void cleanup() {
    input.remove();
  }

  input.addEventListener(
    'change',
    (web.Event event) {
      try {
        final files = input.files;
        if (files == null || files.length == 0) {
          if (!completer.isCompleted) completer.complete(null);
          cleanup();
          return;
        }

        final file = files.item(0);
        if (file == null) {
          if (!completer.isCompleted) completer.complete(null);
          cleanup();
          return;
        }

        final reader = web.FileReader();
        reader.addEventListener(
          'load',
          (web.Event _) {
            try {
              final result = reader.result;
              if (result != null && result.isA<JSArrayBuffer>()) {
                final bytes = (result as JSArrayBuffer).toDart.asUint8List();
                if (!completer.isCompleted) completer.complete(bytes);
              } else {
                if (!completer.isCompleted) completer.complete(null);
              }
            } catch (e) {
              debugPrint('Error converting file array buffer: ');
              if (!completer.isCompleted) completer.complete(null);
            } finally {
              cleanup();
            }
          }.toJS,
        );

        reader.addEventListener(
          'error',
          (web.Event _) {
            debugPrint('FileReader error during backup import');
            if (!completer.isCompleted) completer.complete(null);
            cleanup();
          }.toJS,
        );

        reader.readAsArrayBuffer(file);
      } catch (e) {
        debugPrint('Error in file change event: ');
        if (!completer.isCompleted) completer.complete(null);
        cleanup();
      }
    }.toJS,
  );

  input.addEventListener(
    'cancel',
    (web.Event _) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!completer.isCompleted) completer.complete(null);
        cleanup();
      });
    }.toJS,
  );

  web.document.body?.appendChild(input);
  input.click();

  return completer.future;
}
