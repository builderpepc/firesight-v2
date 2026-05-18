import 'dart:async';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_action.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Tier 3: Gemma 3 1B via Cactus + native STT/TTS (no internet, low-power).
/// NOTE: Galaxy S22 can run Gemma 3 1B via Cactus (viable offline fallback).
class NativeFallbackAgent implements VoiceAgent {
  NativeFallbackAgent(this._stt, this._tts);

  final SpeechToText _stt;
  final FlutterTts _tts;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _processingController = StreamController<bool>.broadcast();
  final _actionController = StreamController<VoiceAction>.broadcast();
  final _audioLevelController = StreamController<double>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<bool> get processingStream => _processingController.stream;

  @override
  Stream<Object> get errorStream => const Stream.empty();

  @override
  Stream<VoiceAction> get actionStream => _actionController.stream;

  @override
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
    // TODO: Initialize Cactus with Gemma 3 1B.
    // Listen via speech_to_text, forward to CactusLM, play responses via flutter_tts.
    // Use history.toJsonList() to prefix messages for multi-turn context.
    
    // Add sound level listener if STT is active
    _stt.initialize(onStatus: (status) {
       if (status == 'listening') {
         // Some STT implementations provide sound level
       }
    }, onError: (error) => {});
  }

  @override
  Future<void> stopListening() async {
    await _stt.stop();
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await _transcriptController.close();
    await _responseController.close();
    await _processingController.close();
    await _actionController.close();
    await _audioLevelController.close();
    await _stt.cancel();
    await _tts.stop();
  }
}
