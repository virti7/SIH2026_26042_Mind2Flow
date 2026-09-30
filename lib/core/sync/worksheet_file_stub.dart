/// Platform file access for downloaded worksheets (interface).
library;

/// Saves opaque [bytes] for [fileName] and returns a storage reference that
/// [readBytes]/[deleteFile] accept later. Implemented per-platform; the
/// download flow depends only on this interface.
abstract class WorksheetFileStore {
  Future<String> saveBytes(String fileName, List<int> bytes);
  Future<List<int>?> readBytes(String storageRef);
  Future<void> deleteFile(String storageRef);
}

/// Resolved through the conditional export so dart:io never leaks onto web.
WorksheetFileStore createPlatformFileStore() {
  throw UnsupportedError('No worksheet file store for this platform.');
}
