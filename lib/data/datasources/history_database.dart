import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/history_entry.dart';

class HistoryDatabase {
  static const String _boxName = 'download_history';

  late Box<Map<dynamic, dynamic>> _box;

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDir.path}/history_db';
    Directory(dbPath).createSync(recursive: true);
    Hive.init(dbPath);
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Future<void> saveEntry(HistoryEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<List<HistoryEntry>> loadAll() async {
    final entries = _box.values
        .map((map) => HistoryEntry.fromMap(Map<String, dynamic>.from(map)))
        .toList();
    // Sort by completedAt descending
    entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return entries;
  }

  Future<HistoryEntry?> getEntry(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    return HistoryEntry.fromMap(Map<String, dynamic>.from(map));
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  Future<void> close() async {
    await _box.close();
  }
}
