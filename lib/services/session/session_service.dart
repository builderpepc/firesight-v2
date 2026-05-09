import 'dart:async';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_storage.dart';

/// CRUD operations for InspectionSession.
class SessionService {
  SessionService(this._storage);

  final SessionStorage _storage;

  /// Lists all session metadata (without full observations).
  Future<List<SessionMetadata>> listSessions() async {
    return _storage.listSessions();
  }

  /// Loads a full session with all observations and building documents.
  Future<InspectionSession?> loadSession(String id) async {
    return _storage.loadSession(id);
  }

  /// Creates a new session.
  Future<InspectionSession> createSession(String name) async {
    return _storage.createSession(name);
  }

  /// Saves session changes (observations, documents, metadata updates).
  Future<void> saveSession(InspectionSession session) async {
    await _storage.saveSession(session);
  }

  /// Deletes a session permanently.
  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
  }

  /// Deletes all sessions.
  Future<void> deleteAllSessions() async {
    await _storage.deleteAllSessions();
  }

  /// Saves an image file permanently and returns the new path.
  Future<String> saveImage(String tempPath) async {
    return _storage.saveImage(tempPath);
  }
}
