import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/models/building_document.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/core/constants.dart';
import 'session_storage.dart';

/// Reads and writes sessions as directories: sessions/`<id>`/session.json
class LocalSessionStorage implements SessionStorage {
  LocalSessionStorage(String basePath)
      : _sessionsDir = Directory('$basePath/${AppPaths.sessions}'),
        _photosDir = Directory('$basePath/${AppPaths.photos}');

  final Directory _sessionsDir;
  final Directory _photosDir;
  final _uuid = const Uuid();

  @override
  Future<void> ensureInitialized() async {
    await _sessionsDir.create(recursive: true);
    await _photosDir.create(recursive: true);
  }

  @override
  Future<String> saveImage(String tempPath) async {
    await ensureInitialized();
    final tempFile = File(tempPath);
    if (!tempFile.existsSync()) {
      throw Exception('Source file does not exist: $tempPath');
    }

    final String ext = extension(tempPath);
    final String fileName = '${_uuid.v4()}$ext';
    final String permanentPath = join(_photosDir.path, fileName);
    await tempFile.copy(permanentPath);
    return permanentPath;
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
    final sessions = <SessionMetadata>[];
    for (final entity in _sessionsDir.listSync()) {
      if (entity is Directory) {
        final metaFile = File('${entity.path}/session.json');
        if (metaFile.existsSync()) {
          final json =
              jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          final session = SessionMetadata.fromJson(json);

          // Apply basic filtering
          if (zipCode != null && session.zipCode != zipCode) continue;
          if (buildingType != null && session.buildingType != buildingType)
            continue;
          if (status != null && session.status != status) continue;
          if (inspectorId != null && session.inspectorId != inspectorId)
            continue;
          if (riskLevel != null && session.riskLevel != riskLevel) continue;

          sessions.add(session);
        }
      }
    }
    return sessions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<InspectionSession?> loadSession(String id) async {
    await ensureInitialized();
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    if (!sessionDir.existsSync()) return null;

    final metaFile = File('${sessionDir.path}/session.json');
    final json =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final session = InspectionSession.fromJson(json);
    final absoluteSession = _applyPathTransformation(session, _toAbsolutePath);
    final normalizedSession = await _normalizeSessionImages(absoluteSession);
    if (normalizedSession != absoluteSession) {
      await _writeSession(sessionDir, normalizedSession);
    }
    return normalizedSession;
  }

  @override
  Future<InspectionSession> createSession(String name) async {
    await ensureInitialized();
    final id = _generateId();
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    await sessionDir.create(recursive: true);

    final session = InspectionSession(
      id: id,
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _writeSession(sessionDir, session);
    return session;
  }

  @override
  Future<void> saveSession(InspectionSession session) async {
    await ensureInitialized();
    final normalizedSession = await _normalizeSessionImages(session);
    final sessionDir = Directory('${_sessionsDir.path}/${session.id}');
    if (!sessionDir.existsSync()) {
      await sessionDir.create(recursive: true);
    }
    await _writeSession(sessionDir, normalizedSession);
  }

  @override
  Future<void> deleteSession(String id) async {
    await ensureInitialized();
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    if (sessionDir.existsSync()) {
      await _deleteSessionAssets(sessionDir);
      await sessionDir.delete(recursive: true);
    }
  }

  @override
  Future<void> deleteAllSessions() async {
    await ensureInitialized();
    if (_sessionsDir.existsSync()) {
      for (final entity in _sessionsDir.listSync()) {
        if (entity is Directory) {
          await _deleteSessionAssets(entity);
          await entity.delete(recursive: true);
        }
      }
    }
  }

  Future<void> _writeSession(
      Directory sessionDir, InspectionSession session) async {
    final storageSession = _applyPathTransformation(session, _toRelativePath);
    final file = File('${sessionDir.path}/session.json');
    await file.writeAsString(jsonEncode(storageSession.toJson()));
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
    if (!sourceFile.existsSync()) {
      return sourcePath;
    }

    final isManaged = dirname(absolutePath) == _photosDir.path;
    if (isManaged) {
      return absolutePath;
    }

    final ext = extension(absolutePath);
    final fileName = '${_uuid.v4()}$ext';
    final permanentPath = join(_photosDir.path, fileName);
    await sourceFile.copy(permanentPath);
    return permanentPath;
  }

  Future<void> _deleteSessionAssets(Directory sessionDir) async {
    final metaFile = File('${sessionDir.path}/session.json');
    if (!metaFile.existsSync()) {
      return;
    }

    final json =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    final session = InspectionSession.fromJson(json);

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
      if (file.existsSync()) {
        await file.delete();
      }
    }
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
    if (isAbsolute(path) && dirname(path) == _photosDir.path) {
      return basename(path);
    }
    return path;
  }

  String? _toAbsolutePath(String? path) {
    if (path == null || path.isEmpty) return path;
    if (!isAbsolute(path)) {
      return join(_photosDir.path, path);
    }
    return path;
  }

  String _generateId() => _uuid.v4();
}
