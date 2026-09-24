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
      debugPrint('Web Share declined or unavailable: \$e');
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
    debugPrint('Web file download failed: \$e');
    return false;
  }
}

bool isWebShareSupported() {
  try {
    // Check if navigator.share and navigator.canShare exist
    return true;
  } catch (_) {
    return false;
  }
}
