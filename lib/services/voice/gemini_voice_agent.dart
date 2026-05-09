import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/audio/audio_output_service.dart';
import 'package:firesight/services/voice/voice_agent.dart';

// Vertex AI native-audio model (audio in, audio out + transcription).
const _kLiveModel = 'gemini-live-2.5-flash-preview-native-audio-09-2025';
// Gemini Live API requires 16 kHz PCM input.
const _kInputSampleRate = 16000;

/// Tier 1: Firebase AI Gemini Live API (internet required).
///
/// Streams microphone audio to Gemini's Live API and emits:
/// - [transcriptStream]: user speech transcriptions (input transcription)
/// - [responseStream]: agent reply transcriptions (output audio transcription)
///
/// Agent audio replies are played back in real time via [AudioOutputService].
/// Native audio PCM chunks from the model are fed directly to SoLoud —
/// no TTS conversion is needed for this tier.
class GeminiVoiceAgent implements VoiceAgent {
  GeminiVoiceAgent(this._firebaseAI, this._audioOutput, {AudioRecorder? recorder})
      : _recorderOverride = recorder;

  final FirebaseAI _firebaseAI;
  final AudioOutputService _audioOutput;
  final AudioRecorder? _recorderOverride;
  AudioRecorder? _recorderInstance;

  // Lazy so tests can construct GeminiVoiceAgent without triggering platform channels.
  AudioRecorder get _recorder => _recorderOverride ?? (_recorderInstance ??= AudioRecorder());

  LiveSession? _session;
  StreamSubscription<LiveServerResponse>? _receiveSub;
  StreamSubscription<Uint8List>? _audioSub;

  // Accumulates partial outputTranscription chunks until turnComplete.
  final _responseBuffer = StringBuffer();

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  @override
  Future<void> startListening(InspectionSession session) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission denied. Please grant it in Settings and try again.');
    }

    await _audioOutput.init();

    final liveModel = _firebaseAI.liveGenerativeModel(
      model: _kLiveModel,
      systemInstruction: Content.system(_buildSystemInstruction(session)),
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
      ),
    );

    _session = await liveModel.connect();

    _receiveSub = _session!.receive().listen(
      _handleResponse,
      onError: (Object error) {
        _errorController.add(error);
        stopListening();
      },
    );

    final audioStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _kInputSampleRate,
        numChannels: 1,
      ),
    );

    // Forward each PCM chunk to the live session via sendAudioRealtime.
    // Stored so it can be cancelled in stopListening.
    // sendAudioRealtime throws synchronously on WebSocket close, so we
    // catch inside the data handler rather than relying on onError.
    _audioSub = audioStream.listen(
      (Uint8List data) {
        try {
          _session?.sendAudioRealtime(InlineDataPart('audio/pcm', data));
        } catch (e) {
          _errorController.add(e);
          stopListening();
        }
      },
      onError: (Object error) {
        _errorController.add(error);
        stopListening();
      },
    );
  }

  @override
  Future<void> stopListening() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    await _receiveSub?.cancel();
    _receiveSub = null;
    _responseBuffer.clear();
    await _audioOutput.stopPlayback();
    // close() can hang if the socket is already broken; cap at 2 s.
    await _session?.close().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    _session = null;
  }

  /// Routes incoming server messages to the appropriate stream.
  void _handleResponse(LiveServerResponse response) {
    final msg = response.message;
    if (msg is! LiveServerContent) return;

    final transcriptText = msg.inputTranscription?.text;
    if (transcriptText != null && transcriptText.isNotEmpty) {
      _transcriptController.add(transcriptText);
    }

    // Accumulate partial output transcription; emit as one entry per turn.
    final responseText = msg.outputTranscription?.text;
    if (responseText != null && responseText.isNotEmpty) {
      _responseBuffer.write(responseText);
    }

    // Agent reply audio — feed PCM chunks directly to the speaker.
    final parts = msg.modelTurn?.parts;
    if (parts != null) {
      for (final part in parts) {
        if (part is InlineDataPart && part.mimeType.startsWith('audio')) {
          _audioOutput.addChunk(part.bytes);
        }
      }
    }

    // Emit the complete response text when Gemini's turn ends.
    if (msg.turnComplete == true) {
      final full = _responseBuffer.toString().trim();
      if (full.isNotEmpty) _responseController.add(full);
      _responseBuffer.clear();
    }
  }

  /// Serialises session context into a system instruction for Gemini.
  String _buildSystemInstruction(InspectionSession session) =>
      buildSystemInstruction(session);

  /// Pure helper exposed for unit testing.
  @visibleForTesting
  static String buildSystemInstruction(InspectionSession session) {
    final lines = session.observations.map((o) {
      final photo = o.photoFileRef != null ? ' [photo: ${o.photoFileRef}]' : '';
      return '- ${o.timestamp.toIso8601String()}: ${o.text ?? '(no text)'}$photo';
    }).join('\n');

    return '''You are a fire inspection AI assistant helping a firefighter conduct a pre-incident survey.
Listen to the inspector. If they make an observation, confirm you noted it concisely.
If they ask a question, answer it based on the existing inspection context.

Inspection: ${session.name}
${lines.isEmpty ? 'No observations recorded yet.' : 'Existing observations:\n$lines'}''';
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _transcriptController.close();
    await _responseController.close();
    await _errorController.close();
  }
}
