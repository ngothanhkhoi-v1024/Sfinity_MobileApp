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
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE user_session ADD COLUMN birthDate TEXT',
          );
          await db.execute(
            'ALTER TABLE user_session ADD COLUMN gender TEXT',
          );
          await db.execute(
            'ALTER TABLE user_session ADD COLUMN address TEXT',
          );
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_session (
            id TEXT PRIMARY KEY,
            email TEXT,
            name TEXT,
            avatar TEXT,
            birthDate TEXT,
            gender TEXT,
            address TEXT,
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
    String? birthDate,
    String? gender,
    String? address,
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
        'birthDate': birthDate ?? '',
        'gender': gender ?? '',
        'address': address ?? '',
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
        'birthDate': user['birthDate'],
        'gender': user['gender'],
        'address': user['address'],
      };
    }
    return null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('user_session');
  }

  Future<void> updateAvatar(String avatarUrl) async {
    final db = await database;
    await db.update(
      'user_session',
      {'avatar': avatarUrl},
      where: 'isLoggedIn = ?',
      whereArgs: [1],
    );
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
