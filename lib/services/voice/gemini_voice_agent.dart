import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/audio/audio_output_service.dart';
import 'package:firesight/services/voice/voice_action.dart';
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
  ConversationHistory? _history;
  // True while Gemini is sending audio output — mic is suppressed to prevent
  // self-echo. SoLoud bypasses Android's audio track so hardware AEC has no
  // reference signal; software gating is the only reliable option.
  bool _geminiSpeaking = false;
  // Guards processingStream so we emit true only once per turn.
  bool _processingEmitted = false;

  // Accumulates partial outputTranscription chunks until turnComplete.
  final _responseBuffer = StringBuffer();
  // Accumulates partial inputTranscription chunks for the current user turn.
  final _transcriptBuffer = StringBuffer();

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _processingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _actionController = StreamController<VoiceAction>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<bool> get processingStream => _processingController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  @override
  Stream<VoiceAction> get actionStream => _actionController.stream;

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
    _history = history;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission denied. Please grant it in Settings and try again.');
    }

    await _audioOutput.init();

    final liveModel = _firebaseAI.liveGenerativeModel(
      model: _kLiveModel,
      systemInstruction: Content.system(_buildSystemInstruction(session, history)),
      liveGenerationConfig: LiveGenerationConfig(
        responseModalities: [ResponseModalities.audio],
        inputAudioTranscription: AudioTranscriptionConfig(),
        outputAudioTranscription: AudioTranscriptionConfig(),
      ),
      tools: [
        Tool.functionDeclarations([
          FunctionDeclaration(
            'record_observation',
            'Records a text observation stated by the inspector.',
            parameters: {
              'text': Schema.string(
                description: 'The observation exactly as stated by the inspector.',
              ),
            },
          ),
          FunctionDeclaration(
            'take_photo',
            'Requests the inspector to photograph something.',
            parameters: {
              'description': Schema.string(
                description: 'What should be photographed.',
              ),
            },
          ),
          FunctionDeclaration(
            'upload_floorplan',
            'Asks the inspector to upload or replace the building floorplan.',
            parameters: {},
          ),
        ]),
      ],
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
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    // Forward each PCM chunk to the live session via sendAudioRealtime.
    // Stored so it can be cancelled in stopListening.
    // sendAudioRealtime throws synchronously on WebSocket close, so we
    // catch inside the data handler rather than relying on onError.
    _audioSub = audioStream.listen(
      (Uint8List data) {
        if (_geminiSpeaking) return; // suppress mic while agent is speaking
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
    _transcriptBuffer.clear();
    _history = null;
    _geminiSpeaking = false;
    _processingEmitted = false;
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
      _transcriptBuffer.write(transcriptText);
      // First inputTranscription means Gemini has heard the user and is
      // generating a response — emit processing=true once per turn.
      if (!_processingEmitted) {
        _processingEmitted = true;
        _processingController.add(true);
      }
    }

    // Accumulate partial output transcription; emit as one entry per turn.
    final responseText = msg.outputTranscription?.text;
    if (responseText != null && responseText.isNotEmpty) {
      _responseBuffer.write(responseText);
    }

    // Agent reply audio and function calls.
    final parts = msg.modelTurn?.parts;
    if (parts != null) {
      for (final part in parts) {
        if (part is InlineDataPart && part.mimeType.startsWith('audio')) {
          _geminiSpeaking = true;
          _audioOutput.addChunk(part.bytes);
        } else if (part is FunctionCall) {
          _handleFunctionCall(part);
        }
      }
    }

    // Emit the complete response text when Gemini's turn ends, and record
    // both sides of the turn in the shared conversation history.
    if (msg.turnComplete == true) {
      final userText = _transcriptBuffer.toString().trim();
      final full = _responseBuffer.toString().trim();

      if (userText.isNotEmpty) _history?.addUser(userText);
      if (full.isNotEmpty) {
        _history?.addAssistant(full);
        _responseController.add(full);
      }

      _transcriptBuffer.clear();
      _responseBuffer.clear();
      _processingEmitted = false;

      // Tell SoLoud no more chunks are coming so it drains the buffer and
      // fires allInstancesFinished. Without this, BufferingType.released
      // keeps the handle alive indefinitely waiting for more data.
      _audioOutput.signalTurnComplete();
      _waitForPlaybackDone();
    }
  }

  void _handleFunctionCall(FunctionCall call) {
    switch (call.name) {
      case 'record_observation':
        final text = call.args['text'] as String?;
        if (text != null && text.isNotEmpty) {
          _actionController.add(RecordObservation(text));
        }
      case 'take_photo':
        final description = call.args['description'] as String?;
        _actionController.add(TakePhoto(description: description));
      case 'upload_floorplan':
        _actionController.add(const UploadFloorplan());
    }
    // Acknowledge — the Live API requires a FunctionResponse to continue.
    _session?.sendToolResponse([
      FunctionResponse(call.name, {'success': true}, id: call.id),
    ]);
  }

  Future<void> _waitForPlaybackDone() async {
    await _audioOutput.waitForPlaybackDone();
    _geminiSpeaking = false;
    _processingController.add(false);
  }

  /// Serialises session context and prior conversation history into a system instruction.
  String _buildSystemInstruction(InspectionSession session, ConversationHistory history) =>
      buildSystemInstruction(session, history);

  /// Pure helper exposed for unit testing.
  @visibleForTesting
  static String buildSystemInstruction(InspectionSession session, ConversationHistory history) {
    final lines = session.observations.map((o) {
      final photo = o.photoFileRef != null ? ' [photo: ${o.photoFileRef}]' : '';
      return '- ${o.timestamp.toIso8601String()}: ${o.text ?? '(no text)'}$photo';
    }).join('\n');

    return '''You are a fire inspection AI assistant helping a firefighter conduct a pre-incident survey.

When the inspector states a factual observation (e.g. "blocked exit", "sprinkler head missing", "door is damaged"), call record_observation immediately with their exact words — do not ask for confirmation first.
When the inspector asks to photograph or document something visually, call take_photo.
When the inspector asks to upload or replace the floorplan, call upload_floorplan.
Confirm each recorded observation with a brief spoken acknowledgement (one sentence).
For questions, answer concisely based on the inspection context.

Inspection: ${session.name}
${lines.isEmpty ? 'No observations recorded yet.' : 'Existing observations:\n$lines'}${history.toSystemPromptBlock()}''';
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _transcriptController.close();
    await _responseController.close();
    await _processingController.close();
    await _errorController.close();
    await _actionController.close();
  }
}
