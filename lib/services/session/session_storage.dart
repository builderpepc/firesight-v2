import 'dart:convert';
import 'dart:io';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/core/constants.dart';

/// Reads/writes session directory (JSON + photo files).
class SessionStorage {
  SessionStorage(this._basePath)
      : _sessionsDir = Directory('$_basePath/${AppPaths.sessions}'),
        _photosDir = Directory('$_basePath/${AppPaths.photos}');

  final String _basePath;
  final Directory _sessionsDir;
  final Directory _photosDir;

  Future<void> ensureInitialized() async {
    await _sessionsDir.create(recursive: true);
    await _photosDir.create(recursive: true);
  }

  Future<List<SessionMetadata>> listSessions() async {
    await ensureInitialized();
    final sessions = <SessionMetadata>[];
    for (final entity in _sessionsDir.listSync()) {
      if (entity.path.endsWith('.json')) {
        final file = File(entity.path);
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        sessions.add(SessionMetadata.fromJson(json));
      }
    }
    return sessions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<InspectionSession?> loadSession(String id) async {
    await ensureInitialized();
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    if (!sessionDir.existsSync()) return null;

    final metaFile = File('${sessionDir.path}/session.json');
    final metaContent = await metaFile.readAsString();
    final metaJson = jsonDecode(metaContent) as Map<String, dynamic>;
    final session = InspectionSession.fromJson(metaJson);

    // TODO: Load building documents from documents.json if it exists.
    return session;
  }

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
    await _writeSessionMetadata(sessionDir, session);
    return session;
  }

  Future<void> saveSession(InspectionSession session) async {
    await ensureInitialized();
    final sessionDir = Directory('${_sessionsDir.path}/${session.id}');
    if (!sessionDir.existsSync()) {
      await sessionDir.create(recursive: true);
    }
    await _writeSessionMetadata(sessionDir, session);
    // TODO: Write observations.json and documents.json files.
  }

  Future<void> deleteSession(String id) async {
    final sessionDir = Directory('${_sessionsDir.path}/$id');
    if (sessionDir.existsSync()) {
      await sessionDir.delete(recursive: true);
    }
  }

  Future<void> _writeSessionMetadata(Directory sessionDir, InspectionSession session) async {
    final file = File('${sessionDir.path}/session.json');
    final json = session.toJson();
    await file.writeAsString(jsonEncode(json));
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}
