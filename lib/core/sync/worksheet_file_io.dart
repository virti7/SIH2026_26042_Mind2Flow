import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'worksheet_file_stub.dart' show WorksheetFileStore;
export 'worksheet_file_stub.dart' show WorksheetFileStore;

/// Native (Android/iOS/desktop) file store: app-private documents directory.
/// Works fully offline; no network, no server, no provider involved.
class NativeWorksheetFileStore implements WorksheetFileStore {  @override
  Future<String> saveBytes(String fileName, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    // Account-scoped layout: callers pass "<ownerUserId>/<file>".
    // Legacy bare filenames stay under the shared folder but are only
    // reachable through ownership-filtered metadata.
    final parts = fileName.split('/');
    final String folderPath;
    final String leaf;
    if (parts.length > 1) {
      final safe = parts.sublist(0, parts.length - 1).map(
        (p) => p.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_'),
      ).where((p) => p.isNotEmpty && p != '.' && p != '..');
      folderPath = ([dir.path, 'accounts', ...safe, 'worksheets']).join('/');
      leaf = parts.last;
    } else {
      folderPath = '${dir.path}/worksheets';
      leaf = fileName;
    }
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final file = File('$folderPath/$leaf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<List<int>?> readBytes(String storageRef) async {
    try {
      final file = File(storageRef);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteFile(String storageRef) async {
    try {
      final file = File(storageRef);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Resolved through the conditional export so dart:io never leaks onto web.
WorksheetFileStore createPlatformFileStore() => NativeWorksheetFileStore();
