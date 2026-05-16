import 'dart:async';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';

/// Abstract voice agent interface.
abstract class VoiceAgent {
  /// Begins capturing and processing audio input.
  ///
  /// [history] is a mutable object shared across agent instances — the agent
  /// appends each completed turn so context survives tier switches and
  /// stop/restart cycles.
  Future<void> startListening(InspectionSession session, ConversationHistory history);

  /// Stops audio capture.
  Future<void> stopListening();

  /// Stream of transcribed user speech (observations or questions).
  Stream<String> get transcriptStream;

  /// Stream of agent text responses (for TTS playback).
  Stream<String> get responseStream;

  /// Emits `true` when the agent begins processing (inference running or
  /// waiting for a remote response) and `false` when it finishes.
  /// Used to drive a loading indicator in the UI.
  Stream<bool> get processingStream;

  /// Emits errors that terminate the session (e.g. WebSocket closed).
  /// Listeners should call [stopListening] and reset UI state on receipt.
  Stream<Object> get errorStream;

  Future<void> dispose();
}
