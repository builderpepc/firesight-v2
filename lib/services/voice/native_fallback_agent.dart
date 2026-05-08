import 'dart:async';
import 'package:firesight/models/inspection_session.dart';
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

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<Object> get errorStream => const Stream.empty();

  @override
  Future<void> startListening(InspectionSession session) async {
    // TODO: Initialize Cactus with Gemma 3 1B.
    // Listen via speech_to_text, forward to CactusLM, play responses via flutter_tts.
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
    await _stt.cancel();
    await _tts.stop();
  }
}
