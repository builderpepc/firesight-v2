import 'dart:async';
import 'package:firesight/models/inspection_session.dart';

/// Abstract voice agent interface.
abstract class VoiceAgent {
  /// Begins capturing and processing audio input.
  Future<void> startListening(InspectionSession session);

  /// Stops audio capture.
  Future<void> stopListening();

  /// Stream of transcribed user speech (observations or questions).
  Stream<String> get transcriptStream;

  /// Stream of agent text responses (for TTS playback).
  Stream<String> get responseStream;

  Future<void> dispose();
}
