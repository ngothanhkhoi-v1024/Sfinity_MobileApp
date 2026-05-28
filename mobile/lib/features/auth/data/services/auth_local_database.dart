import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AuthLocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sfinity_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_session (
            id TEXT PRIMARY KEY,
            email TEXT,
            name TEXT,
            avatar TEXT,
            accessToken TEXT,
            isLoggedIn INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveSession({
    required String uid,
    required String email,
    required String name,
    String? avatar,
    required String accessToken,
  }) async {
    final db = await database;
    await db.insert(
      'user_session',
      {
        'id': uid,
        'email': email,
        'name': name,
        'avatar': avatar ?? '',
        'accessToken': accessToken,
        'isLoggedIn': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getToken() async {
    final db = await database;
    final maps = await db.query(
      'user_session',
      columns: ['accessToken'],
      where: 'isLoggedIn = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['accessToken'] as String?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    final db = await database;
    final maps = await db.query(
      'user_session',
      where: 'isLoggedIn = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      final user = maps.first;
      return {
        'id': user['id'],
        'email': user['email'],
        'name': user['name'],
        'avatar': user['avatar'],
      };
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('user_session');
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}