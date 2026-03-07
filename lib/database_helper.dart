import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:project_xmedit/models/claim_models.dart';
import 'package:sqflite/sqflite.dart';

class CodeDescription {
  final String shortDescription;
  final String fullDescription;

  const CodeDescription({
    required this.shortDescription,
    required this.fullDescription,
  });
}

class ClinicianProfile {
  final String clinicianId;
  final String professionalName;
  final String? specialtyId;
  final String? specialtyDescription;

  const ClinicianProfile({
    required this.clinicianId,
    required this.professionalName,
    this.specialtyId,
    this.specialtyDescription,
  });
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static const _dbName = 'codes.db';
  static const _dbVersion = 4;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await _ensureSeedDatabase(path);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < _dbVersion) return;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_codes(
        service_type TEXT NOT NULL,
        code TEXT NOT NULL,
        code_normalized TEXT NOT NULL,
        short_desc TEXT NOT NULL,
        full_desc TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY(service_type, code_normalized)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_service_type_code ON service_codes(service_type, code)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_service_type_code_norm ON service_codes(service_type, code_normalized)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS icd10_codes(
        code TEXT PRIMARY KEY,
        code_normalized TEXT NOT NULL,
        short_desc TEXT NOT NULL,
        full_desc TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_icd10_code_norm ON icd10_codes(code_normalized)');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS payers(
        payer_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        classification TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS specialties(
        specialty_id TEXT PRIMARY KEY,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS clinicians(
        clinician_id TEXT PRIMARY KEY,
        professional_name TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 1,
        specialty_id TEXT,
        specialty_description TEXT,
        source_sheet TEXT
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_clinician_name ON clinicians(professional_name)');
  }

  Future<void> _ensureSeedDatabase(String path) async {
    if (await databaseExists(path)) {
      return;
    }
    final data =
        await rootBundle.load('assets/db_seed/reference_seed.sqlite.gz');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final sqliteBytes = GZipDecoder().decodeBytes(bytes);
    await databaseFactory.writeDatabaseBytes(path, sqliteBytes);
  }

  String _mapActivityTypeToServiceType(String? activityType) {
    switch (activityType) {
      case '3':
        return 'CPT';
      case '6':
        return 'CDT';
      case '8':
        return 'DSL';
      case '5':
        return 'DRUG';
      default:
        return '';
    }
  }

  String _normalizeNumericCode(String code) {
    final raw = code.trim();
    if (raw.isEmpty) return '';
    final numericRegex = RegExp(r'^[-+]?\d+(\.\d+)?$');
    if (!numericRegex.hasMatch(raw)) return raw.toUpperCase();
    var clean = raw;
    var sign = '';
    if (clean.startsWith('-')) {
      sign = '-';
      clean = clean.substring(1);
    }
    if (clean.contains('.')) {
      final parts = clean.split('.');
      final left = parts[0];
      final right = parts[1].replaceFirst(RegExp(r'0+$'), '');
      clean = right.isEmpty ? left : '$left.$right';
    }
    return '$sign$clean';
  }

  String _normalizeServiceCode(String serviceType, String code) {
    final raw = code.trim();
    if (raw.isEmpty) return '';
    switch (serviceType) {
      case 'CPT':
        final numericRegex = RegExp(r'^\d+(\.0+)?$');
        if (numericRegex.hasMatch(raw)) {
          final asInt = int.tryParse(raw.split('.').first) ?? 0;
          return asInt.toString().padLeft(5, '0');
        }
        return raw.toUpperCase();
      case 'DSL':
        return _normalizeNumericCode(raw);
      default:
        return raw.toUpperCase();
    }
  }

  String _lookupKey(String? activityType, String? code) =>
      '${activityType ?? ''}|${code ?? ''}';

  Future<Map<String, CodeDescription>> getDescriptionsForActivities(
      List<ActivityData> activities) async {
    if (activities.isEmpty) return {};
    final db = await database;

    final requestMap = <String, Map<String, Set<String>>>{};
    for (final activity in activities) {
      final serviceType = _mapActivityTypeToServiceType(activity.type);
      final code = activity.code?.trim() ?? '';
      if (serviceType.isEmpty || code.isEmpty) continue;
      final normalized = _normalizeServiceCode(serviceType, code);
      if (normalized.isEmpty) continue;
      requestMap.putIfAbsent(serviceType, () => <String, Set<String>>{});
      requestMap[serviceType]!
          .putIfAbsent(normalized, () => <String>{})
          .add(_lookupKey(activity.type, activity.code));
    }

    final out = <String, CodeDescription>{};

    for (final entry in requestMap.entries) {
      final serviceType = entry.key;
      final normalizedCodes = entry.value.keys.toList(growable: false);
      if (normalizedCodes.isEmpty) continue;
      final placeholders = List.filled(normalizedCodes.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
        SELECT code_normalized, short_desc, full_desc
        FROM service_codes
        WHERE service_type = ? AND code_normalized IN ($placeholders) AND active = 1
        ''',
        [serviceType, ...normalizedCodes],
      );

      for (final row in rows) {
        final norm = row['code_normalized'] as String;
        final shortDesc = (row['short_desc'] as String?) ?? '';
        final fullDesc = (row['full_desc'] as String?) ?? shortDesc;
        final keys = entry.value[norm] ?? const <String>{};
        for (final key in keys) {
          out[key] = CodeDescription(
            shortDescription: shortDesc,
            fullDescription: fullDesc,
          );
        }
      }
    }

    return out;
  }

  Future<CodeDescription?> getIcd10DescriptionData(String code) async {
    final clean = code.trim();
    if (clean.isEmpty) return null;
    final db = await database;
    final normalized = clean.toUpperCase().replaceAll('.', '');
    final maps = await db.query(
      'icd10_codes',
      columns: ['short_desc', 'full_desc'],
      where: '(code = ? OR code_normalized = ?) AND active = 1',
      whereArgs: [clean.toUpperCase(), normalized],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final shortDesc = maps.first['short_desc'] as String? ?? '';
    final fullDesc = maps.first['full_desc'] as String? ?? shortDesc;
    return CodeDescription(
        shortDescription: shortDesc, fullDescription: fullDesc);
  }

  Future<Map<String, CodeDescription>> getIcd10Descriptions(
      Set<String> codes) async {
    if (codes.isEmpty) return {};
    final db = await database;

    final cleanedCodes = codes
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .toSet();
    if (cleanedCodes.isEmpty) return {};

    final normalizedCodes =
        cleanedCodes.map((c) => c.replaceAll('.', '')).toSet();

    final codePlaceholders = List.filled(cleanedCodes.length, '?').join(',');
    final normalizedPlaceholders =
        List.filled(normalizedCodes.length, '?').join(',');

    final rows = await db.rawQuery(
      '''
      SELECT code, code_normalized, short_desc, full_desc
      FROM icd10_codes
      WHERE active = 1
        AND (code IN ($codePlaceholders) OR code_normalized IN ($normalizedPlaceholders))
      ''',
      [...cleanedCodes, ...normalizedCodes],
    );

    final byAnyKey = <String, CodeDescription>{};
    for (final row in rows) {
      final shortDesc = (row['short_desc'] as String?) ?? '';
      final fullDesc = (row['full_desc'] as String?) ?? shortDesc;
      final code = (row['code'] as String?)?.toUpperCase() ?? '';
      final codeNormalized = (row['code_normalized'] as String?) ?? '';
      final desc = CodeDescription(
        shortDescription: shortDesc,
        fullDescription: fullDesc,
      );
      if (code.isNotEmpty) byAnyKey[code] = desc;
      if (codeNormalized.isNotEmpty) byAnyKey[codeNormalized] = desc;
    }

    final out = <String, CodeDescription>{};
    for (final code in cleanedCodes) {
      final normalized = code.replaceAll('.', '');
      final found = byAnyKey[code] ?? byAnyKey[normalized];
      if (found != null) out[code] = found;
    }
    return out;
  }

  Future<String?> getIcd10Description(String code) async {
    final data = await getIcd10DescriptionData(code);
    return data?.shortDescription;
  }

  Future<List<MapEntry<String, String>>> searchIcd10(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final db = await database;
    final maps = await db.query(
      'icd10_codes',
      columns: ['code', 'short_desc', 'full_desc'],
      where:
          'code LIKE ? OR code_normalized LIKE ? OR short_desc LIKE ? OR full_desc LIKE ?',
      whereArgs: ['%$q%', '%$q%', '%$q%', '%$q%'],
      limit: 60,
    );
    return maps
        .map((map) => MapEntry(
              map['code'] as String,
              (map['short_desc'] as String?) ??
                  (map['full_desc'] as String?) ??
                  '',
            ))
        .toList();
  }

  Future<String?> getPayerName(String payerId) async {
    final id = payerId.trim().toUpperCase();
    if (id.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      'payers',
      columns: ['name'],
      where: 'payer_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['name'] as String?;
  }

  Future<String?> getClinicianName(String clinicianId) async {
    final profile = await getClinicianProfile(clinicianId);
    return profile?.professionalName;
  }

  Future<ClinicianProfile?> getClinicianProfile(String clinicianId) async {
    final id = clinicianId.trim().toUpperCase();
    if (id.isEmpty) return null;
    final db = await database;
    final maps = await db.query(
      'clinicians',
      columns: [
        'clinician_id',
        'professional_name',
        'specialty_id',
        'specialty_description',
      ],
      where: 'clinician_id = ? AND status = 1',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final row = maps.first;
    return ClinicianProfile(
      clinicianId: (row['clinician_id'] as String?) ?? id,
      professionalName: (row['professional_name'] as String?) ?? '',
      specialtyId: row['specialty_id'] as String?,
      specialtyDescription: row['specialty_description'] as String?,
    );
  }

  Future<void> warmupCoreReferenceData() async {
    await database;
  }

  Future<void> resetToSeedDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final existing = _database;
    if (existing != null && existing.isOpen) {
      await existing.close();
    }
    _database = null;

    if (await databaseExists(path)) {
      await deleteDatabase(path);
    }

    await _ensureSeedDatabase(path);
    _database = await _initDb();
  }
}
