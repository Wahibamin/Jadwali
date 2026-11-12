import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/prayer_model.dart';
import '../models/task_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  static const String _databaseName = 'smart_daily_planner.db';
  static const int _databaseVersion = 3;
  static const String _tasksTable = 'tasks';
  static const String _prayersTable = 'prayers';

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= _initializeDatabase();
  }

  Future<Database> _initializeDatabase() async {
    final databasesDirectory = await getDatabasesPath();
    final databasePath =
        '$databasesDirectory${Platform.pathSeparator}$_databaseName';

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $_tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        priority INTEGER NOT NULL,
        status TEXT NOT NULL CHECK (
          status IN (
            '${Task.pendingStatus}',
            '${Task.completedStatus}',
            '${Task.overdueStatus}'
          )
        ),
        isHidden INTEGER NOT NULL CHECK (isHidden IN (0, 1)),
        isMuted INTEGER NOT NULL DEFAULT 0 CHECK (isMuted IN (0, 1)),
        date TEXT NOT NULL
      )
    ''');

    await _createPrayersTable(database);
  }

  Future<void> _createPrayersTable(Database database) async {
    await database.execute('''
      CREATE TABLE $_prayersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        status TEXT,
        isCongregation INTEGER,
        rakatCaught INTEGER,
        totalRakat INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await database.execute(
        'ALTER TABLE $_tasksTable '
        'ADD COLUMN isMuted INTEGER NOT NULL DEFAULT 0;',
      );
    }

    if (oldVersion < 3) {
      await _createPrayersTable(database);
    }
  }

  Future<int> insertTask(Task task) async {
    final database = await this.database;
    return database.insert(_tasksTable, task.toMap());
  }

  Future<List<Task>> getTasksByDate(String date) async {
    final database = await this.database;
    final maps = await database.query(
      _tasksTable,
      where: 'date = ?',
      whereArgs: <Object?>[date],
      orderBy: 'startTime ASC, id ASC',
    );

    return maps.map(Task.fromMap).toList(growable: false);
  }

  Future<int> updateTask(Task task) async {
    final id = task.id;
    if (id == null) {
      throw ArgumentError('A task must have an id before it can be updated.');
    }

    final database = await this.database;
    return database.update(
      _tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteTask(int id) async {
    final database = await this.database;
    return database.delete(
      _tasksTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteAllTasks() async {
    final database = await this.database;
    return database.delete(_tasksTable);
  }

  Future<int> deleteCompletedTasks() async {
    final database = await this.database;
    return database.delete(
      _tasksTable,
      where: 'status = ?',
      whereArgs: <Object?>[Task.completedStatus],
    );
  }

  Future<int> insertPrayer(Prayer prayer) async {
    final database = await this.database;
    return database.insert(_prayersTable, prayer.toMap());
  }

  Future<int> updatePrayer(Prayer prayer) async {
    final id = prayer.id;
    if (id == null) {
      throw ArgumentError('A prayer must have an id before it can be updated.');
    }

    final database = await this.database;
    return database.update(
      _prayersTable,
      prayer.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<Prayer>> getPrayersByDate(String date) async {
    final database = await this.database;
    final maps = await database.query(
      _prayersTable,
      where: 'date = ?',
      whereArgs: <Object?>[date],
      orderBy: 'id ASC',
    );

    return maps.map(Prayer.fromMap).toList(growable: false);
  }

  Future<List<Prayer>> getAllPrayers() async {
    final database = await this.database;
    final maps = await database.query(
      _prayersTable,
      orderBy: 'date ASC, id ASC',
    );

    return maps.map(Prayer.fromMap).toList(growable: false);
  }
}
