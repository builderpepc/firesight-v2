import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Tier 1: Firebase AI Gemini Live API (internet required).
class GeminiVoiceAgent implements VoiceAgent {
  GeminiVoiceAgent(this._model);

  final GenerativeModel _model;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Future<void> startListening(InspectionSession session) async {
    // TODO: Implement Gemini Live API audio streaming.
    // Requires firebase_ai package with LiveGenerativeModel.
    // Will need to handle bidirectional audio and text streams.
  }

  @override
  Future<void> stopListening() async {
    // TODO: Close LiveGenerativeModel session.
  }

  @override
  Future<void> dispose() async {
    await _transcriptController.close();
    await _responseController.close();
  }
}
