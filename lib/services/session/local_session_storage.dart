import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:firesight/models/building_document.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/models/session_metadata.dart';
import 'session_storage.dart';

/// File-based [SessionStorage] implementation. Matches the on-disk layout
/// prescribed by PROJECT.md (sessions as directories + metadata JSON +
/// photo files), with an `index.json` for O(1) metadata listing.
///
/// Layout (under [basePath]):
///   `sessions/<id>/session.json`   — full session as JSON
///   `sessions/index.json`          — list of metadata for fast listing
///   `photos/<filename>`            — managed photo files referenced by sessions
///
/// Photo file references inside `session.json` are stored as basenames
/// (relative to `photos/`); they are resolved to absolute paths on load.
class LocalSessionStorage implements SessionStorage {
  LocalSessionStorage(String basePath)
      : _sessionsDir = Directory(join(basePath, 'sessions')),
        _photosDir = Directory(join(basePath, 'photos')),
        _indexFile = File(join(basePath, 'sessions', 'index.json'));

  final Directory _sessionsDir;
  final Directory _photosDir;
  final File _indexFile;
  final _uuid = const Uuid();

  /// In-memory mirror of `sessions/index.json`, keyed by session id.
  final Map<String, SessionMetadata> _index = {};
  bool _initialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _sessionsDir.create(recursive: true);
    await _photosDir.create(recursive: true);
    await _loadOrRebuildIndex();
    _initialized = true;
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
    final result = _index.values.where((m) {
      if (zipCode != null && m.zipCode != zipCode) return false;
      if (buildingType != null && m.buildingType != buildingType) return false;
      if (status != null && m.status != status) return false;
      if (inspectorId != null && m.inspectorId != inspectorId) return false;
      if (riskLevel != null && m.riskLevel != riskLevel) return false;
      return true;
    }).toList();
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<InspectionSession?> loadSession(String id) async {
    await ensureInitialized();
    final file = _sessionJsonFile(id);
    if (!await file.exists()) return null;

    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final stored = InspectionSession.fromJson(raw);
    final absoluteSession = _applyPathTransformation(stored, _toAbsolutePath);
    final normalized = await _normalizeSessionImages(absoluteSession);
    if (normalized != absoluteSession) {
      await _writeSession(normalized);
      _index[normalized.id] = _metadataFromSession(normalized);
      await _writeIndex();
    }
    return normalized;
  }

  @override
  Future<InspectionSession> createSession(String name) async {
    await ensureInitialized();
    final now = DateTime.now();
    final session = InspectionSession(
      id: _uuid.v4(),
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
    final normalized = await _normalizeSessionImages(session);
    await _writeSession(normalized);
    _index[normalized.id] = _metadataFromSession(normalized);
    await _writeIndex();
  }

  @override
  Future<void> deleteSession(String id) async {
    await ensureInitialized();
    final session = await loadSession(id);
    if (session != null) {
      await _deleteSessionAssets(session);
    }
    final dir = Directory(join(_sessionsDir.path, id));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _index.remove(id);
    await _writeIndex();
  }

  @override
  Future<void> deleteAllSessions() async {
    await ensureInitialized();
    for (final id in _index.keys.toList()) {
      final session = await loadSession(id);
      if (session != null) {
        await _deleteSessionAssets(session);
      }
    }
    if (await _sessionsDir.exists()) {
      await _sessionsDir.delete(recursive: true);
    }
    await _sessionsDir.create(recursive: true);
    _index.clear();
    await _writeIndex();
  }

  @override
  Future<String> saveImage(String tempPath) async {
    await ensureInitialized();
    final source = File(tempPath);
    if (!await source.exists()) {
      throw Exception('Source file does not exist: $tempPath');
    }
    final fileName = '${_uuid.v4()}${extension(tempPath)}';
    final permanentPath = join(_photosDir.path, fileName);
    await source.copy(permanentPath);
    return permanentPath;
  }

  // --- Internals -----------------------------------------------------------

  File _sessionJsonFile(String id) =>
      File(join(_sessionsDir.path, id, 'session.json'));

  /// Writes [session] as `sessions/<id>/session.json`. Photo refs are
  /// stored as basenames so the file is portable across installs.
  Future<void> _writeSession(InspectionSession session) async {
    final dir = Directory(join(_sessionsDir.path, session.id));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final stored = _applyPathTransformation(session, _toRelativePath);
    await _sessionJsonFile(session.id)
        .writeAsString(jsonEncode(stored.toJson()));
  }

  /// Loads `sessions/index.json` into [_index]. If the file is missing or
  /// corrupted, the index is rebuilt by scanning `sessions/<id>/session.json`.
  Future<void> _loadOrRebuildIndex() async {
    _index.clear();
    if (await _indexFile.exists()) {
      try {
        final raw = jsonDecode(await _indexFile.readAsString());
        if (raw is List) {
          for (final entry in raw) {
            final meta =
                SessionMetadata.fromJson(entry as Map<String, dynamic>);
            _index[meta.id] = meta;
          }
          return;
        }
      } catch (_) {
        // Fall through to rebuild.
      }
    }
    await _rebuildIndexFromDisk();
    await _writeIndex();
  }

  Future<void> _rebuildIndexFromDisk() async {
    if (!await _sessionsDir.exists()) return;
    await for (final entity in _sessionsDir.list()) {
      if (entity is! Directory) continue;
      final id = basename(entity.path);
      final sessionFile = _sessionJsonFile(id);
      if (!await sessionFile.exists()) continue;
      try {
        final raw =
            jsonDecode(await sessionFile.readAsString()) as Map<String, dynamic>;
        final session = InspectionSession.fromJson(raw);
        _index[session.id] = _metadataFromSession(session);
      } catch (_) {
        // Skip corrupted session files; they won't appear in listings but
        // remain on disk for manual inspection.
      }
    }
  }

  Future<void> _writeIndex() async {
    final list = _index.values.map((m) => m.toJson()).toList();
    await _indexFile.writeAsString(jsonEncode(list));
  }

  /// Copies any photo references that live outside `photos/` into it,
  /// returning a session whose paths are managed (absolute, inside [_photosDir]).
  Future<InspectionSession> _normalizeSessionImages(
    InspectionSession session,
  ) async {
    final floorplanPath = await _ensureManagedImage(session.floorplanPath);
    final observations = <Observation>[];
    for (final obs in session.observations) {
      observations.add(obs.copyWith(
        photoFileRef: await _ensureManagedImage(obs.photoFileRef),
      ));
    }
    final buildingDocuments = <BuildingDocument>[];
    for (final doc in session.buildingDocuments) {
      buildingDocuments.add(doc.copyWith(
        filePath: await _ensureManagedImage(doc.filePath) ?? doc.filePath,
      ));
    }
    return session.copyWith(
      floorplanPath: floorplanPath,
      observations: observations,
      buildingDocuments: buildingDocuments,
    );
  }

  Future<String?> _ensureManagedImage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return sourcePath;
    final absolute = _toAbsolutePath(sourcePath)!;
    final sourceFile = File(absolute);
    if (!await sourceFile.exists()) return sourcePath;
    if (dirname(absolute) == _photosDir.path) return absolute;

    final fileName = '${_uuid.v4()}${extension(absolute)}';
    final managed = join(_photosDir.path, fileName);
    await sourceFile.copy(managed);
    return managed;
  }

  Future<void> _deleteSessionAssets(InspectionSession session) async {
    final paths = <String>{
      if (session.floorplanPath != null) _toAbsolutePath(session.floorplanPath)!,
      ...session.observations
          .where((o) => o.photoFileRef != null)
          .map((o) => _toAbsolutePath(o.photoFileRef)!),
      ...session.buildingDocuments.map((d) => _toAbsolutePath(d.filePath)!),
    };
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
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
      observations: session.observations
          .map((o) => o.copyWith(photoFileRef: transform(o.photoFileRef)))
          .toList(),
      buildingDocuments: session.buildingDocuments
          .map((d) => d.copyWith(
                filePath: transform(d.filePath) ?? d.filePath,
              ))
          .toList(),
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
    if (!isAbsolute(path)) return join(_photosDir.path, path);
    return path;
  }

  SessionMetadata _metadataFromSession(InspectionSession s) => SessionMetadata(
        id: s.id,
        name: s.name,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        zipCode: s.zipCode,
        buildingType: s.buildingType,
        status: s.status,
        inspectorId: s.inspectorId,
        riskLevel: s.riskLevel,
      );
}
