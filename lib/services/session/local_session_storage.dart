import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/core/constants.dart';
import 'session_storage_interface.dart';

/// Reads and writes sessions as directories: sessions/<id>/session.json
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
          final json = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
          final session = SessionMetadata.fromJson(json);
          
          // Apply basic filtering
          if (zipCode != null && session.zipCode != zipCode) continue;
          if (buildingType != null && session.buildingType != buildingType) continue;
          if (status != null && session.status != status) continue;
          if (inspectorId != null && session.inspectorId != inspectorId) continue;
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
    final json = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    return InspectionSession.fromJson(json);
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
    final sessionDir = Directory('${_sessionsDir.path}/${session.id}');
    if (!sessionDir.existsSync()) {
      await sessionDir.create(recursive: true);
    }
    await _writeSession(sessionDir, session);
  }

  @override
  Future<void> deleteSession(String id) async {
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    if (sessionDir.existsSync()) {
      await sessionDir.delete(recursive: true);
    }
  }

  Future<void> _writeSession(Directory sessionDir, InspectionSession session) async {
    final file = File('${sessionDir.path}/session.json');
    await file.writeAsString(jsonEncode(session.toJson()));
  }

  String _generateId() => _uuid.v4();
}
