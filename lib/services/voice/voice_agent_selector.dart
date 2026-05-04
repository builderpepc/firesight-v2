// ignore_for_file: unused_import
import 'dart:async';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/voice/gemini_voice_agent.dart';
import 'package:firesight/services/voice/cactus_voice_agent.dart';
import 'package:firesight/services/voice/native_fallback_agent.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:firesight/core/constants.dart';

/// Factory: selects voice agent tier based on connectivity + device capability.
/// Tier selection logic:
/// 1. Internet available → GeminiVoiceAgent
/// 2. No internet, high-power device → CactusVoiceAgent (Gemma 4) - NOT VIABLE ON S22
/// 3. No internet, low-power device → NativeFallbackAgent (Gemma 3 1B)
VoiceAgent createVoiceAgent({
  required ConnectivityService connectivity,
}) {
  final isOnlineStream = connectivity.isOnline;
  // TODO: Return appropriate agent based on online status and device capabilities.
  return _OnlineStatusAgent(isOnlineStream);
}

class _OnlineStatusAgent implements VoiceAgent {
  _OnlineStatusAgent(this._isOnlineStream);

  final Stream<bool> _isOnlineStream;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Future<void> startListening(InspectionSession session) async {
    _isOnlineStream.listen((isOnline) {
      // TODO: Switch agents dynamically based on connectivity.
    });
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> dispose() async {
    await _transcriptController.close();
    await _responseController.close();
  }
}
