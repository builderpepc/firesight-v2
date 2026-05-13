import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/voice/mock_voice_agent.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Holds all voice agent dependencies and selects the active tier based on
/// connectivity and device capability.
///
/// Tier selection:
///   1. Internet available       → GeminiVoiceAgent (firebase_ai Live API)
///   2. No internet, ≥6 GB RAM  → CactusVoiceAgent (Gemma 4 E4B/E2B)
///   3. No internet, low-power  → NativeFallbackAgent (Gemma 3 1B + native STT/TTS)
class VoiceAgentService {
  VoiceAgentService({
    required this.connectivity,
    required this.stt,
    required this.tts,
  });

  final ConnectivityService connectivity;
  final SpeechToText stt;
  final FlutterTts tts;
  VoiceAgent? _cachedAgent;

  // TODO: inject GenerativeModel factory (Tier 1, Gemini) and CactusLM factory
  // (Tiers 2/3) during voice feature implementation.

  /// Returns the active voice agent. Until real tier selection is implemented,
  /// returns a [MockVoiceAgent] so the in-app voice contract (start/stop,
  /// transcript/response streams, tool callbacks) can be exercised end-to-end.
  // TODO: replace with real tier selection — check connectivity.isOnline and
  // device RAM, return GeminiVoiceAgent / CactusVoiceAgent / NativeFallbackAgent.
  VoiceAgent get currentAgent => _cachedAgent ??= MockVoiceAgent();

  Future<void> dispose() async {
    await _cachedAgent?.dispose();
    _cachedAgent = null;
  }
}
