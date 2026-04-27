import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import '../models/family_member.dart';

class DatabaseRepository {
  static final DatabaseRepository _instance = DatabaseRepository._internal();
  factory DatabaseRepository() => _instance;
  DatabaseRepository._internal();

  Database? _db;
  final _secureStorage = const FlutterSecureStorage();
  encrypt.Encrypter? _encrypter;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  /// 初始化或加载加密密钥
  Future<void> _initEncryptionKey() async {
    String? keyBase64 = await _secureStorage.read(key: 'db_encryption_key');
    if (keyBase64 == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyBase64 = base64Encode(key.bytes);
      await _secureStorage.write(key: 'db_encryption_key', value: keyBase64);
    }
    final key = encrypt.Key.fromBase64(keyBase64);
    _encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  }

  String _encrypt(String plainText) {
    if (_encrypter == null) return plainText;
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  String _decrypt(String? cipherText) {
    if (cipherText == null || cipherText.isEmpty) return '';
    if (_encrypter == null) return cipherText;
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return cipherText;
      final iv = encrypt.IV.fromBase64(parts[0]);
      return _encrypter!.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return cipherText;
    }
  }

  Future<Database> _initDatabase() async {
    await _initEncryptionKey();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConfig.dbName);

    return await openDatabase(
      path,
      version: DbConfig.dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE family_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birthday_type INTEGER NOT NULL DEFAULT 0,
            lunar_month INTEGER,
            lunar_day INTEGER,
            solar_year INTEGER,
            solar_month INTEGER,
            solar_day INTEGER,
            lunar_reminder_time TEXT,
            solar_reminder_time TEXT,
            repeat_rule INTEGER NOT NULL DEFAULT 0,
            custom_interval_days INTEGER,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        // 插入默认设置
        await db.insert('app_settings', {'key': 'popup_duration', 'value': '${AppDefaults.popupDuration}'});
        await db.insert('app_settings', {'key': 'sound_enabled', 'value': '${AppDefaults.soundEnabled}'});
        await db.insert('app_settings', {'key': 'snooze_interval', 'value': '${AppDefaults.snoozeInterval}'});
      },
    );
  }

  // ================== CRUD ==================

  Future<int> addMember(FamilyMember member) async {
    final db = await database;
    final map = member.toMap();
    map['name'] = _encrypt(member.name);
    return await db.insert('family_members', map);
  }

  Future<int> updateMember(FamilyMember member) async {
    final db = await database;
    final map = member.toMap();
    map['name'] = _encrypt(member.name);
    return await db.update(
      'family_members',
      map,
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  Future<FamilyMember?> getMemberById(int id) async {
    final db = await database;
    final maps = await db.query('family_members', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final map = Map<String, dynamic>.from(maps.first);
    map['name'] = _decrypt(map['name'] as String?);
    return FamilyMember.fromMap(map);
  }

  Future<List<FamilyMember>> getAllMembers() async {
    final db = await database;
    final maps = await db.query('family_members', orderBy: 'created_at DESC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['name'] = _decrypt(map['name'] as String?);
      return FamilyMember.fromMap(map);
    }).toList();
  }

  Future<List<FamilyMember>> searchMembers(String keyword) async {
    final all = await getAllMembers();
    final lower = keyword.toLowerCase();
    return all.where((m) => m.name.toLowerCase().contains(lower)).toList();
  }

  // ================== Settings ==================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ================== Backup ==================

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, DbConfig.dbName);
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
