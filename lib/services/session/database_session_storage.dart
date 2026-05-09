import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/models/building_document.dart';
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

    final whereString =
        whereClauses.isEmpty ? null : whereClauses.join(' AND ');

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
    final session = InspectionSession.fromJson(
      jsonDecode(dataJson) as Map<String, dynamic>,
    );
    final absoluteSession = _applyPathTransformation(session, _toAbsolutePath);
    final normalizedSession = await _normalizeSessionImages(absoluteSession);
    if (normalizedSession != absoluteSession) {
      await _saveNormalizedSession(normalizedSession);
    }
    return normalizedSession;
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
    final normalizedSession = await _normalizeSessionImages(session);
    await _saveNormalizedSession(normalizedSession);
  }

  Future<void> _saveNormalizedSession(
      InspectionSession normalizedSession) async {
    final storageSession =
        _applyPathTransformation(normalizedSession, _toRelativePath);
    final dataJson = jsonEncode(storageSession.toJson());

    final row = {
      'id': normalizedSession.id,
      'name': normalizedSession.name,
      'createdAt': normalizedSession.createdAt.toIso8601String(),
      'updatedAt': normalizedSession.updatedAt.toIso8601String(),
      'zipCode': normalizedSession.zipCode,
      'buildingType': normalizedSession.buildingType,
      'status': normalizedSession.status,
      'inspectorId': normalizedSession.inspectorId,
      'riskLevel': normalizedSession.riskLevel,
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
    final session = await loadSession(id);
    if (session != null) {
      await _deleteSessionAssets(session);
    }
    await _db!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllSessions() async {
    await ensureInitialized();
    final sessions = await _db!.query(_tableName, columns: ['data']);
    for (final row in sessions) {
      final session = InspectionSession.fromJson(
        jsonDecode(row['data'] as String) as Map<String, dynamic>,
      );
      await _deleteSessionAssets(session);
    }
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

  Future<void> _deleteSessionAssets(InspectionSession session) async {
    final filePaths = <String>{
      if (session.floorplanPath != null) _toAbsolutePath(session.floorplanPath)!,
      ...session.observations
          .where((observation) => observation.photoFileRef != null)
          .map((observation) => _toAbsolutePath(observation.photoFileRef)!),
      ...session.buildingDocuments
          .map((doc) => _toAbsolutePath(doc.filePath)!),
    };

    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<InspectionSession> _normalizeSessionImages(
    InspectionSession session,
  ) async {
    final floorplanPath = await _ensureManagedImage(session.floorplanPath);
    final observations = <Observation>[];

    for (final observation in session.observations) {
      observations.add(
        observation.copyWith(
          photoFileRef: await _ensureManagedImage(observation.photoFileRef),
        ),
      );
    }

    final buildingDocuments = <BuildingDocument>[];
    for (final doc in session.buildingDocuments) {
      buildingDocuments.add(
        doc.copyWith(
          filePath: await _ensureManagedImage(doc.filePath) ?? doc.filePath,
        ),
      );
    }

    return session.copyWith(
      floorplanPath: floorplanPath,
      observations: observations,
      buildingDocuments: buildingDocuments,
    );
  }

  Future<String?> _ensureManagedImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) {
      return sourcePath;
    }

    final absolutePath = _toAbsolutePath(sourcePath)!;
    final sourceFile = File(absolutePath);
    if (!await sourceFile.exists()) {
      return sourcePath;
    }

    final isManaged = dirname(absolutePath) == _photosDir!.path;
    if (isManaged) {
      return absolutePath;
    }

    final ext = extension(absolutePath);
    final fileName = '${_uuid.v4()}$ext';
    final permanentPath = join(_photosDir!.path, fileName);
    await sourceFile.copy(permanentPath);
    return permanentPath;
  }

  InspectionSession _applyPathTransformation(
    InspectionSession session,
    String? Function(String?) transform,
  ) {
    return session.copyWith(
      floorplanPath: transform(session.floorplanPath),
      observations: session.observations.map((obs) {
        return obs.copyWith(
          photoFileRef: transform(obs.photoFileRef),
        );
      }).toList(),
      buildingDocuments: session.buildingDocuments.map((doc) {
        return doc.copyWith(
          filePath: transform(doc.filePath) ?? doc.filePath,
        );
      }).toList(),
    );
  }

  String? _toRelativePath(String? path) {
    if (path == null || path.isEmpty) return path;
    if (isAbsolute(path) && dirname(path) == _photosDir!.path) {
      return basename(path);
    }
    return path;
  }

  String? _toAbsolutePath(String? path) {
    if (path == null || path.isEmpty) return path;
    if (!isAbsolute(path)) {
      return join(_photosDir!.path, path);
    }
    return path;
  }
}
