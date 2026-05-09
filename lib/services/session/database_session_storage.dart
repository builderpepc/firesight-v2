import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';
import 'session_storage.dart';

class DatabaseSessionStorage implements SessionStorage {
  DatabaseSessionStorage();

  static const String _tableName = 'sessions';
  Database? _db;
  final _uuid = const Uuid();
  Directory? _photosDir;

  @override
  Future<void> ensureInitialized() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'firesight.db');

    final appDocDir = await getApplicationDocumentsDirectory();
    _photosDir = Directory(join(appDocDir.path, 'photos'));
    await _photosDir!.create(recursive: true);

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            zipCode TEXT,
            buildingType TEXT,
            status TEXT,
            inspectorId TEXT,
            riskLevel TEXT,
            data TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<List<SessionMetadata>> listSessions({
    String? zipCode,
    String? buildingType,
    String? status,
    String? inspectorId,
    String? riskLevel,
  }) async {
    await ensureInitialized();

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (zipCode != null) {
      whereClauses.add('zipCode = ?');
      whereArgs.add(zipCode);
    }
    if (buildingType != null) {
      whereClauses.add('buildingType = ?');
      whereArgs.add(buildingType);
    }
    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }
    if (inspectorId != null) {
      whereClauses.add('inspectorId = ?');
      whereArgs.add(inspectorId);
    }
    if (riskLevel != null) {
      whereClauses.add('riskLevel = ?');
      whereArgs.add(riskLevel);
    }

    final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      columns: [
        'id',
        'name',
        'createdAt',
        'updatedAt',
        'zipCode',
        'buildingType',
        'status',
        'inspectorId',
        'riskLevel'
      ],
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return SessionMetadata(
        id: maps[i]['id'],
        name: maps[i]['name'],
        createdAt: DateTime.parse(maps[i]['createdAt']),
        updatedAt: DateTime.parse(maps[i]['updatedAt']),
        zipCode: maps[i]['zipCode'],
        buildingType: maps[i]['buildingType'],
        status: maps[i]['status'],
        inspectorId: maps[i]['inspectorId'],
        riskLevel: maps[i]['riskLevel'],
      );
    });
  }

  @override
  Future<InspectionSession?> loadSession(String id) async {
    await ensureInitialized();

    final List<Map<String, dynamic>> maps = await _db!.query(
      _tableName,
      columns: ['data'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final String dataJson = maps[0]['data'];
    return InspectionSession.fromJson(jsonDecode(dataJson));
  }

  @override
  Future<InspectionSession> createSession(String name) async {
    await ensureInitialized();

    final id = _uuid.v4();
    final now = DateTime.now();
    final session = InspectionSession(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    await saveSession(session);
    return session;
  }

  @override
  Future<void> saveSession(InspectionSession session) async {
    await ensureInitialized();

    final dataJson = jsonEncode(session.toJson());
    
    final row = {
      'id': session.id,
      'name': session.name,
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
      'zipCode': session.zipCode,
      'buildingType': session.buildingType,
      'status': session.status,
      'inspectorId': session.inspectorId,
      'riskLevel': session.riskLevel,
      'data': dataJson,
    };

    await _db!.insert(
      _tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSession(String id) async {
    await ensureInitialized();
    await _db!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllSessions() async {
    await ensureInitialized();
    await _db!.delete(_tableName);
  }

  @override
  Future<String> saveImage(String tempPath) async {
    await ensureInitialized();
    
    final File tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      throw Exception('Source file does not exist: $tempPath');
    }

    final String ext = extension(tempPath);
    final String fileName = '${_uuid.v4()}$ext';
    final String permanentPath = join(_photosDir!.path, fileName);
    
    await tempFile.copy(permanentPath);
    return permanentPath;
  }
}
