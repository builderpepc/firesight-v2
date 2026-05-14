import 'package:cactus/cactus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';

class MockCactusLM extends Mock implements CactusLM {}

CactusModel _model(String slug, String name) => CactusModel(
      createdAt: DateTime(2026),
      slug: slug,
      downloadUrl: 'https://example.com/$slug',
      sizeMb: 100,
      supportsToolCalling: false,
      supportsVision: false,
      name: name,
    );

// Integration tests (actual model load / microphone) require a physical device.
// These unit tests cover the pure message-builder and slug-resolver logic.

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

  group('resolveGemma4Slug', () {
    late MockCactusLM cactus;

    setUp(() => cactus = MockCactusLM());

    test('returns E2B slug when registry has a matching model', () async {
      when(() => cactus.getModels()).thenAnswer((_) async => [
            _model('gemma4-e2b', 'Gemma 4 E2B'),
            _model('gemma4-e4b', 'Gemma 4 E4B'),
          ]);
      final slug = await resolveGemma4Slug(cactus, kGemma4E2bSlug);
      expect(slug, 'gemma4-e2b');
    });

    test('returns E4B slug when E4B hint is given', () async {
      when(() => cactus.getModels()).thenAnswer((_) async => [
            _model('gemma4-e2b', 'Gemma 4 E2B'),
            _model('gemma4-e4b', 'Gemma 4 E4B'),
          ]);
      final slug = await resolveGemma4Slug(cactus, kGemma4E4bSlug);
      expect(slug, 'gemma4-e4b');
    });

    test('falls back to any Gemma 4 model when preferred size absent', () async {
      when(() => cactus.getModels()).thenAnswer((_) async => [
            _model('gemma4-e2b', 'Gemma 4 E2B'),
          ]);
      // Ask for E4B but only E2B is available.
      final slug = await resolveGemma4Slug(cactus, kGemma4E4bSlug);
      expect(slug, 'gemma4-e2b');
    });

    test('returns null when no Gemma 4 models are in the registry', () async {
      when(() => cactus.getModels()).thenAnswer((_) async => [
            _model('qwen3-0.6', 'Qwen 3 0.6B'),
          ]);
      final slug = await resolveGemma4Slug(cactus, kGemma4E2bSlug);
      expect(slug, isNull);
    });

    test('returns null when getModels throws', () async {
      when(() => cactus.getModels()).thenThrow(Exception('network error'));
      final slug = await resolveGemma4Slug(cactus, kGemma4E2bSlug);
      expect(slug, isNull);
    });

    test('matches slug that contains gemma and 4 in different positions', () async {
      when(() => cactus.getModels()).thenAnswer((_) async => [
            _model('google-gemma-4-e2b-instruct', 'Google Gemma 4 E2B Instruct'),
          ]);
      final slug = await resolveGemma4Slug(cactus, kGemma4E2bSlug);
      expect(slug, 'google-gemma-4-e2b-instruct');
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
