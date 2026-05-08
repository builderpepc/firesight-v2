import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/session_metadata.dart';

abstract class SessionStorage {
  Future<List<SessionMetadata>> listSessions({
    String? zipCode,
    String? buildingType,
    String? status,
    String? inspectorId,
    String? riskLevel,
  });
  Future<InspectionSession?> loadSession(String id);
  Future<InspectionSession> createSession(String name);
  Future<void> saveSession(InspectionSession session);
  Future<void> deleteSession(String id);
  Future<void> ensureInitialized();
}
