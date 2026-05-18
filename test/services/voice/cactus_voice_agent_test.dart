import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';

class _MockTts extends Mock implements FlutterTts {}

// Integration tests (actual model load / microphone) require a physical device.
// These unit tests cover the pure message-builder and constant logic.

void main() {
  final history = ConversationHistory();
  group('CactusVoiceAgent.buildSystemPrompt', () {
    test('references session name', () {
      final session = _session(name: 'Station 7 — Warehouse B');
      final result = CactusVoiceAgent.buildSystemPrompt(session, history);
      expect(result, contains('Station 7 — Warehouse B'));
    });

    test('reports no observations when list is empty', () {
      final result = CactusVoiceAgent.buildSystemPrompt(_session(), history);
      expect(result, contains('No observations recorded yet.'));
    });

    test('includes existing observations in system prompt', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13, 9, 0),
        text: 'Sprinkler head blocked by shelving',
      );
      final result = CactusVoiceAgent.buildSystemPrompt(
        _session(observations: [obs]),
        history,
      );
      expect(result, contains('Sprinkler head blocked by shelving'));
    });

    test('appends photo reference when present', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Missing exit sign',
        photoFileRef: 'photos/img001.jpg',
      );
      final result = CactusVoiceAgent.buildSystemPrompt(
        _session(observations: [obs]),
        history,
      );
      expect(result, contains('[photo: photos/img001.jpg]'));
    });

    test('omits photo reference when absent', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Door closes properly',
      );
      final result = CactusVoiceAgent.buildSystemPrompt(
        _session(observations: [obs]),
        history,
      );
      expect(result, isNot(contains('[photo:')));
    });

    test('handles observation with null text', () {
      final obs = Observation(id: '1', timestamp: DateTime(2026, 5, 13));
      final result = CactusVoiceAgent.buildSystemPrompt(
        _session(observations: [obs]),
        history,
      );
      expect(result, contains('(no text)'));
    });

    test('system prompt mentions offline context', () {
      final result = CactusVoiceAgent.buildSystemPrompt(_session(), history);
      expect(result, contains('offline'));
    });
  });

  group('CactusVoiceAgent.startListening — missing model file', () {
    test('emits StateError on errorStream when model file does not exist', () async {
      final agent = CactusVoiceAgent(
        '/nonexistent/path/gemma-4-e2b-it-int4.gguf',
        _MockTts(),
      );
      final errors = <Object>[];
      final sub = agent.errorStream.listen(errors.add);

      final session = InspectionSession(
        id: 'test',
        name: 'Test',
        createdAt: DateTime(2026, 5, 14),
        updatedAt: DateTime(2026, 5, 14),
      );
      await agent.startListening(session, history);
      await sub.cancel();

      expect(errors, hasLength(1));
      expect(errors.first, isA<StateError>());
      expect((errors.first as StateError).message, contains('not found'));
    });
  });

  group('Gemma 4 model hint slug constants', () {
    test('E2B slug is non-empty', () {
      expect(kGemma4E2bSlug, isNotEmpty);
    });

    test('E4B slug is non-empty and different from E2B', () {
      expect(kGemma4E4bSlug, isNotEmpty);
      expect(kGemma4E4bSlug, isNot(equals(kGemma4E2bSlug)));
    });

    test('E2B and E4B slugs are accessible from cactus_voice_agent', () {
      const e2b = kGemma4E2bSlug;
      const e4b = kGemma4E4bSlug;
      expect(e2b, isNotEmpty);
      expect(e4b, isNotEmpty);
    });
  });
}

List<Map<String, dynamic>> _decode(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>();

InspectionSession _session({
  String name = 'Test Inspection',
  List<Observation> observations = const [],
}) =>
    InspectionSession(
      id: 'test-id',
      name: name,
      createdAt: DateTime(2026, 5, 13),
      updatedAt: DateTime(2026, 5, 13),
      observations: observations,
    );

