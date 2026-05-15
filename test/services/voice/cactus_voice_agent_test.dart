import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';

class _MockStt extends Mock implements SpeechToText {}
class _MockTts extends Mock implements FlutterTts {}

// Integration tests (actual model load / microphone) require a physical device.
// These unit tests cover the pure message-builder and constant logic.

void main() {
  group('CactusVoiceAgent.buildMessages', () {
    test('system message references session name', () {
      final session = _session(name: 'Station 7 — Warehouse B');
      final decoded = _decode(CactusVoiceAgent.buildMessages(session, 'Any text'));
      expect(decoded[0]['role'], 'system');
      expect(decoded[0]['content'], contains('Station 7 — Warehouse B'));
    });

    test('user message contains the utterance verbatim', () {
      final session = _session();
      final decoded = _decode(CactusVoiceAgent.buildMessages(session, 'Exit door blocked'));
      expect(decoded[1]['role'], 'user');
      expect(decoded[1]['content'], 'Exit door blocked');
    });

    test('produces exactly two messages: system then user', () {
      final decoded = _decode(CactusVoiceAgent.buildMessages(_session(), 'hello'));
      expect(decoded.length, 2);
      expect(decoded[0]['role'], 'system');
      expect(decoded[1]['role'], 'user');
    });

    test('reports no observations when list is empty', () {
      final decoded = _decode(CactusVoiceAgent.buildMessages(_session(), 'hello'));
      expect(decoded[0]['content'], contains('No observations recorded yet.'));
    });

    test('includes existing observations in system prompt', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13, 9, 0),
        text: 'Sprinkler head blocked by shelving',
      );
      final decoded = _decode(CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      ));
      expect(decoded[0]['content'], contains('Sprinkler head blocked by shelving'));
    });

    test('appends photo reference when present', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Missing exit sign',
        photoFileRef: 'photos/img001.jpg',
      );
      final decoded = _decode(CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      ));
      expect(decoded[0]['content'], contains('[photo: photos/img001.jpg]'));
    });

    test('omits photo reference when absent', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Door closes properly',
      );
      final decoded = _decode(CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      ));
      expect(decoded[0]['content'], isNot(contains('[photo:')));
    });

    test('handles observation with null text', () {
      final obs = Observation(id: '1', timestamp: DateTime(2026, 5, 13));
      final decoded = _decode(CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      ));
      expect(decoded[0]['content'], contains('(no text)'));
    });

    test('system prompt mentions offline context', () {
      final decoded = _decode(CactusVoiceAgent.buildMessages(_session(), 'hello'));
      expect(decoded[0]['content'], contains('offline'));
    });

    test('output is valid JSON', () {
      final json = CactusVoiceAgent.buildMessages(_session(), 'test');
      expect(() => jsonDecode(json), returnsNormally);
    });
  });

  group('CactusVoiceAgent.startListening — missing model file', () {
    test('emits StateError on errorStream when model file does not exist', () async {
      final agent = CactusVoiceAgent(
        '/nonexistent/path/gemma-4-e2b-it-int4.gguf',
        _MockStt(),
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
      await agent.startListening(session);
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

