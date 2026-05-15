import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/services/audio/audio_output_service.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/device/device_capability_service.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/native_fallback_agent.dart';
import 'package:firesight/services/voice/voice_agent.dart';

// Devices with ≥6 GB RAM get E4B; ≥4 GB get E2B; below falls to Tier 3.
const _kE4bRamThresholdGb = 6;
const _kTier2RamThresholdGb = 4;

/// Selects the appropriate voice agent tier based on connectivity and device RAM.
///
/// Tier 1 (online)           → GeminiVoiceAgent (Firebase AI Live API)
/// Tier 2 (offline, ≥4 GB)  → CactusVoiceAgent (Gemma 4 E4B or E2B via Cactus)
/// Tier 3 (offline, <4 GB)  → NativeFallbackAgent (Gemma 3 1B + native STT/TTS)
class VoiceAgentService {
  VoiceAgentService({
    required this.connectivity,
    required this.stt,
    required this.tts,
    required this.firebaseAI,
    required this.audioOutput,
    required this.deviceCapability,
    this.modelBasePath,
  });

  final ConnectivityService connectivity;
  final SpeechToText stt;
  final FlutterTts tts;
  final FirebaseAI firebaseAI;
  final AudioOutputService audioOutput;
  final DeviceCapabilityService deviceCapability;

  /// Override for the model base directory. If null, resolved from
  /// [getApplicationDocumentsDirectory] at resolution time.
  final String? modelBasePath;

  /// Returns the appropriate agent for current connectivity and device capability.
  Future<VoiceAgent> resolveAgent() async {
    final online = await connectivity.checkOnline();
    if (online) return GeminiVoiceAgent(firebaseAI, audioOutput);

    final ramGb = await deviceCapability.totalRamGb();
    if (ramGb != null && ramGb >= _kTier2RamThresholdGb) {
      final slug = ramGb >= _kE4bRamThresholdGb ? kGemma4E4bSlug : kGemma4E2bSlug;
      final basePath =
          modelBasePath ?? (await getApplicationDocumentsDirectory()).path;
      final path = '$basePath/cactus/$slug';
      return CactusVoiceAgent(path, stt, tts);
    }

    return NativeFallbackAgent(stt, tts);
  }
}
