/// Platform stub for non-web environments (tests, desktop, mobile).
Future<bool> saveOrShareBackupPlatform({
  required String jsonContent,
  required String fileName,
  bool preferShare = false,
}) async {
  return true;
}

bool isWebShareSupported() => false;
