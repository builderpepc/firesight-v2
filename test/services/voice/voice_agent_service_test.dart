import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/voice_agent_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}
class MockFirebaseAI extends Mock implements FirebaseAI {}
class MockFlutterTts extends Mock implements FlutterTts {}
class MockSpeechToText extends Mock implements SpeechToText {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivityService connectivity;
  late MockFirebaseAI firebaseAI;
  late VoiceAgentService service;

  setUp(() {
    connectivity = MockConnectivityService();
    firebaseAI = MockFirebaseAI();
    service = VoiceAgentService(
      connectivity: connectivity,
      stt: MockSpeechToText(),
      tts: MockFlutterTts(),
      firebaseAI: firebaseAI,
    );
  });

  group('VoiceAgentService.resolveAgent', () {
    test('returns GeminiVoiceAgent when online', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => true);

      final agent = await service.resolveAgent();

      expect(agent, isA<GeminiVoiceAgent>());
    });

    test('throws UnimplementedError when offline', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);

      expect(
        () => service.resolveAgent(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('calls checkOnline each time to pick up connectivity changes', () async {
      when(() => connectivity.checkOnline()).thenAnswer((_) async => true);
      await service.resolveAgent();

      when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
      expect(() => service.resolveAgent(), throwsA(isA<UnimplementedError>()));

      verify(() => connectivity.checkOnline()).called(2);
    });
  });
}
