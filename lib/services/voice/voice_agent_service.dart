import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
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

  // TODO: inject GenerativeModel factory (Tier 1, Gemini) and CactusLM factory
  // (Tiers 2/3) during voice feature implementation.

  /// Returns the appropriate agent for current conditions.
  VoiceAgent get currentAgent {
    // TODO: implement tier selection — check connectivity.isOnline and device RAM,
    // return GeminiVoiceAgent, CactusVoiceAgent, or NativeFallbackAgent accordingly.
    throw UnimplementedError('VoiceAgentService.currentAgent: TODO');
  }
}
