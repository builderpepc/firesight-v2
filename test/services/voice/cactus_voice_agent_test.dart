import 'package:flutter_test/flutter_test.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';

// Integration tests (actual model load / microphone) require a physical device.
// These unit tests cover the pure message-builder logic.

void main() {
  group('CactusVoiceAgent.buildMessages', () {
    test('system message references session name', () {
      final session = _session(name: 'Station 7 — Warehouse B');
      final messages = CactusVoiceAgent.buildMessages(session, 'Any text');
      final system = messages.first;
      expect(system.role, 'system');
      expect(system.content, contains('Station 7 — Warehouse B'));
    });

    test('user message contains the utterance verbatim', () {
      final session = _session();
      final messages = CactusVoiceAgent.buildMessages(session, 'Exit door blocked');
      final user = messages.last;
      expect(user.role, 'user');
      expect(user.content, 'Exit door blocked');
    });

    test('produces exactly two messages: system then user', () {
      final messages = CactusVoiceAgent.buildMessages(_session(), 'hello');
      expect(messages.length, 2);
      expect(messages[0].role, 'system');
      expect(messages[1].role, 'user');
    });

    test('reports no observations when list is empty', () {
      final messages = CactusVoiceAgent.buildMessages(_session(), 'hello');
      expect(messages.first.content, contains('No observations recorded yet.'));
    });

    test('includes existing observations in system prompt', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13, 9, 0),
        text: 'Sprinkler head blocked by shelving',
      );
      final messages = CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      );
      expect(messages.first.content, contains('Sprinkler head blocked by shelving'));
    });

    test('appends photo reference when present', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Missing exit sign',
        photoFileRef: 'photos/img001.jpg',
      );
      final messages = CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      );
      expect(messages.first.content, contains('[photo: photos/img001.jpg]'));
    });

    test('omits photo reference when absent', () {
      final obs = Observation(
        id: '1',
        timestamp: DateTime(2026, 5, 13),
        text: 'Door closes properly',
      );
      final messages = CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      );
      expect(messages.first.content, isNot(contains('[photo:')));
    });

    test('handles observation with null text', () {
      final obs = Observation(id: '1', timestamp: DateTime(2026, 5, 13));
      final messages = CactusVoiceAgent.buildMessages(
        _session(observations: [obs]),
        'hello',
      );
      expect(messages.first.content, contains('(no text)'));
    });

    test('system prompt mentions offline context', () {
      final messages = CactusVoiceAgent.buildMessages(_session(), 'hello');
      expect(messages.first.content, contains('offline'));
    });
  });

  group('CactusVoiceAgent model slug constants', () {
    test('E2B slug is non-empty', () {
      expect(kGemma4E2bSlug, isNotEmpty);
    });

    test('E4B slug is non-empty and different from E2B', () {
      expect(kGemma4E4bSlug, isNotEmpty);
      expect(kGemma4E4bSlug, isNot(equals(kGemma4E2bSlug)));
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
      createdAt: DateTime(2026, 5, 13),
      updatedAt: DateTime(2026, 5, 13),
      observations: observations,
    );
