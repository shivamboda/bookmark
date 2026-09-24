import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<bool> requestStoragePersistence() async {
  try {
    final jsBool = await web.window.navigator.storage.persist().toDart;
    return jsBool.toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> checkStoragePersistence() async {
  try {
    final jsBool = await web.window.navigator.storage.persisted().toDart;
    return jsBool.toDart;
  } catch (_) {
    return false;
  }
}
