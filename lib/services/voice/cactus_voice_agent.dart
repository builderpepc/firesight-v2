// ignore_for_file: unused_field
import 'dart:async';
import 'package:cactus/cactus.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Tier 2: CactusLM with Gemma 4 (no internet, capable device).
/// NOTE: Galaxy S22 cannot run Gemma 4 reliably. Selector should fall through to tier 3.
class CactusVoiceAgent implements VoiceAgent {
  CactusVoiceAgent(this._cactus);

  final CactusLM _cactus;

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
    // TODO: Initialize CactusLM with Gemma 4 model.
    // Requires cactusInit, model loading, and streaming generation.
  }

  @override
  Future<void> stopListening() async {
    // TODO: Stop CactusLM processing.
  }

  @override
  Future<void> dispose() async {
    await _transcriptController.close();
    await _responseController.close();
    // TODO: Release CactusLM model resources.
  }
}
