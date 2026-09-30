import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor connectDatabase() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'maatribhasha.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      // In flutter test environments where path_provider method channel is unmocked
      return NativeDatabase.memory();
    }
  });
}
