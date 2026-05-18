import 'package:flutter_test/flutter_test.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';

// Integration tests (actual Firebase/microphone) require a device/emulator.
// These unit tests cover the pure system-instruction builder.

void main() {
  final history = ConversationHistory();
  group('GeminiVoiceAgent.buildSystemInstruction', () {
    test('includes session name', () {
      final session = _session(name: 'Station 4 — Warehouse A');
      final result = GeminiVoiceAgent.buildSystemInstruction(session, history);
      expect(result, contains('Station 4 — Warehouse A'));
    });

    test('reports no observations when list is empty', () {
      final result = GeminiVoiceAgent.buildSystemInstruction(_session(), history);
      expect(result, contains('No observations recorded yet.'));
    });

    test('serialises observations as bullet points', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 7, 10, 30),
        text: 'Sprinkler head blocked by shelving',
      );
      final result =
          GeminiVoiceAgent.buildSystemInstruction(_session(observations: [obs]), history);
      expect(result, contains('Sprinkler head blocked by shelving'));
      expect(result, contains('2026-05-07'));
    });

    test('appends photo reference when present', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 7),
        text: 'Exit sign missing',
        photoFileRef: 'photos/img001.jpg',
      );
      final result =
          GeminiVoiceAgent.buildSystemInstruction(_session(observations: [obs]), history);
      expect(result, contains('[photo: photos/img001.jpg]'));
    });

    test('omits photo reference when absent', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 7),
        text: 'Door closes properly',
      );
      final result =
          GeminiVoiceAgent.buildSystemInstruction(_session(observations: [obs]), history);
      expect(result, isNot(contains('[photo:')));
    });

    test('handles observation with null text', () {
      final obs = Observation(id: '1', timestamp: DateTime(2026, 5, 7));
      final result =
          GeminiVoiceAgent.buildSystemInstruction(_session(observations: [obs]), history);
      expect(result, contains('(no text)'));
    });

    test('includes all observations in order', () {
      final obs1 = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 7, 9, 0),
        text: 'First observation',
      );
      final obs2 = Observation(
        id: '2',
        timestamp: DateTime(2026, 5, 7, 9, 5),
        text: 'Second observation',
      );
      final result = GeminiVoiceAgent.buildSystemInstruction(
        _session(observations: [obs1, obs2]),
        history,
      );
      expect(result.indexOf('First observation'),
          lessThan(result.indexOf('Second observation')));
    });
  });
}

InspectionSession _session({
  String name = 'Test Inspection',
  List<Observation> observations = const [],
}) =>
    InspectionSession(
      id: 'test-id',
      name: name,
      createdAt: DateTime(2026, 5, 7),
      updatedAt: DateTime(2026, 5, 7),
      observations: observations,
    );
