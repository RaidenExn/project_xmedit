import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'codes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cpt_codes(
        code TEXT PRIMARY KEY,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE icd10_codes(
        code TEXT PRIMARY KEY,
        description TEXT
      )
    ''');
    await _importFromJson(db);
  }

  Future<void> _importFromJson(Database db) async {
    // Import CPT codes
    final String cptJsonString =
        await rootBundle.loadString('assets/code_descriptions.json');
    final Map<String, dynamic> cptMap = json.decode(cptJsonString);
    final cptBatch = db.batch();
    cptMap.forEach((key, value) {
      cptBatch.insert('cpt_codes', {'code': key, 'description': value});
    });
    await cptBatch.commit(noResult: true);

    // Import ICD-10 codes
    final String icd10JsonString =
        await rootBundle.loadString('assets/icd10.json');
    final Map<String, dynamic> icd10Map = json.decode(icd10JsonString);
    final icd10Batch = db.batch();
    icd10Map.forEach((key, value) {
      icd10Batch.insert('icd10_codes', {'code': key, 'description': value});
    });
    await icd10Batch.commit(noResult: true);
  }

  Future<Map<String, String>> getDescriptionsForCptCodes(
      Set<String> codes) async {
    if (codes.isEmpty) return {};
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cpt_codes',
      where: 'code IN (${List.filled(codes.length, '?').join(',')})',
      whereArgs: codes.toList(),
    );
    return {for (var map in maps) map['code']: map['description']};
  }

  Future<String?> getIcd10Description(String code) async {
    if (code.isEmpty) return null;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'icd10_codes',
      columns: ['description'],
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['description'] as String?;
    }
    return null;
  }

  Future<List<MapEntry<String, String>>> searchIcd10(String query) async {
    if (query.isEmpty) return [];
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'icd10_codes',
      where: 'code LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
    return maps
        .map((map) =>
            MapEntry(map['code'] as String, map['description'] as String))
        .toList();
  }
}