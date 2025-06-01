import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class DBHelper {
  static Database? _db;
  static const int _version = 1;
  static const String _tableName = 'tasks';

  static Future<void> initDb() async {
    if (_db != null) {
      debugPrint('db not null');
      return;
    }
    try {
      String path = '${await getDatabasesPath()}task.db';
      debugPrint('in db path');

      _db = await openDatabase(path, version: _version,
          onCreate: (Database db, int version) async {
        debugPrint('Creating new one');
        // When creating the db, create the table
        return db.execute('CREATE TABLE $_tableName ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title STRING, note TEXT, date STRING, '
            'startTime STRING, endTime STRING, '
            'remind INTEGER, repeat STRING, '
            'recurringEventId TEXT, '
            'color INTEGER, '
            'eventId TEXT, '
            'isCompleted INTEGER)');
      });
      print('DB Created');
    } catch (e) {
      print(e);
    }
  }

  static Future<int> insert(Task? task) async {
    try {
      return await _db!.insert(_tableName, task!.toJson());
    } catch (e) {
      return 9000;
    }
  }

  static Future<int> delete(Task task) async {
    return await _db!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteAll() async {
    return await _db!.delete(_tableName);
  }

  static Future<List<Map<String, dynamic>>> query() async {
    return await _db!.query(_tableName);
  }

  static Future<int> update(Task task) async {
    return await _db!.update(
      _tableName,
      task.toJson(),
      where: 'eventId = ?',
      whereArgs: [task.eventId],
    );
  }

  static Future<Task?> getTaskById(int id) async {
    final db = _db!;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Task.fromJson(maps.first);
    }
    return null;
  }

  static Future<int> mark(int id) async {
    print('UPDATE FUNC FROM DBHELPER');
    return await _db!.rawUpdate('''
    UPDATE tasks
    SET isCompleted = ?
    WHERE id = ?
    ''', [1, id]);
  }
}
