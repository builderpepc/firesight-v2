import 'package:cactus/cactus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/audio/audio_output_service.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/device/device_capability_service.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/native_fallback_agent.dart';
import 'package:firesight/services/voice/voice_agent_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}
class MockFirebaseAI extends Mock implements FirebaseAI {}
class MockFlutterTts extends Mock implements FlutterTts {}
class MockSpeechToText extends Mock implements SpeechToText {}
class MockAudioOutputService extends Mock implements AudioOutputService {}
class MockDeviceCapabilityService extends Mock implements DeviceCapabilityService {}
class MockCactusLM extends Mock implements CactusLM {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityService connectivity;
  late MockDeviceCapabilityService deviceCapability;
  late MockCactusLM cactus;
  late VoiceAgentService service;

  setUp(() {
    connectivity = MockConnectivityService();
    deviceCapability = MockDeviceCapabilityService();
    cactus = MockCactusLM();
    service = VoiceAgentService(
      connectivity: connectivity,
      stt: MockSpeechToText(),
      tts: MockFlutterTts(),
      firebaseAI: MockFirebaseAI(),
      audioOutput: MockAudioOutputService(),
      deviceCapability: deviceCapability,
      cactus: cactus,
    );
  });

  group('VoiceAgentService.resolveAgent', () {
    test('returns GeminiVoiceAgent when online', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => true);

      final agent = await service.resolveAgent();

      expect(agent, isA<GeminiVoiceAgent>());
    });

    test('does not query device RAM when online', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => true);
      await service.resolveAgent();
      verifyNever(() => deviceCapability.totalRamGb());
    });

    test('returns CactusVoiceAgent with E4B slug when offline and ≥6 GB RAM', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => 8);

      final agent = await service.resolveAgent();

      expect(agent, isA<CactusVoiceAgent>());
      expect((agent as CactusVoiceAgent).modelSlug, kGemma4E4bSlug);
    });

    test('returns CactusVoiceAgent with E2B slug when offline and 4–5 GB RAM', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => 5);

      final agent = await service.resolveAgent();

      expect(agent, isA<CactusVoiceAgent>());
      expect((agent as CactusVoiceAgent).modelSlug, kGemma4E2bSlug);
    });

    test('returns NativeFallbackAgent when offline and <4 GB RAM', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => 3);

      final agent = await service.resolveAgent();

      expect(agent, isA<NativeFallbackAgent>());
    });

    test('returns NativeFallbackAgent when offline and RAM is unknown (null)', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => null);

      final agent = await service.resolveAgent();

      expect(agent, isA<NativeFallbackAgent>());
    });

    test('calls checkOnline each invocation to pick up connectivity changes', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => true);
      await service.resolveAgent();

      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => null);
      await service.resolveAgent();

      verify(() => connectivity.checkOnline()).called(2);
    });

    test('E2B threshold: exactly 4 GB selects CactusVoiceAgent', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => 4);

      final agent = await service.resolveAgent();
      expect(agent, isA<CactusVoiceAgent>());
    });

    test('E4B threshold: exactly 6 GB selects E4B model', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      when(() => deviceCapability.totalRamGb()).thenAnswer((_) async => 6);

      final agent = await service.resolveAgent();
      expect((agent as CactusVoiceAgent).modelSlug, kGemma4E4bSlug);
    });
  });
}
