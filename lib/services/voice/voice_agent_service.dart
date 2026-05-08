import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Selects the appropriate voice agent tier based on connectivity.
///
/// Tier 1 (online)  → GeminiVoiceAgent (Firebase AI Live API)
/// Tier 2/3 (offline) → not yet implemented; throws [UnimplementedError]
class VoiceAgentService {
  VoiceAgentService({
    required this.connectivity,
    required this.stt,
    required this.tts,
    required this.firebaseAI,
  });

  final ConnectivityService connectivity;
  final SpeechToText stt;
  final FlutterTts tts;
  final FirebaseAI firebaseAI;

  /// Returns the appropriate agent for current conditions.
  ///
  /// Throws [UnimplementedError] when offline (Tiers 2 & 3 are pending).
  Future<VoiceAgent> resolveAgent() async {
    final online = await connectivity.checkOnline();
    if (online) return GeminiVoiceAgent(firebaseAI);
    throw UnimplementedError(
      'Offline voice agents (Tiers 2 & 3) are not yet implemented.',
    );
  }
}
