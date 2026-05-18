import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:firesight/cactus.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_action.dart';
import 'package:firesight/services/voice/voice_agent.dart';

// Top-level functions for compute() — must not capture any mutable state.
// Pointer addresses cross isolate boundaries as plain ints; native memory is shared.

int _initCactusModel(String modelPath) => cactusInit(modelPath, null, false).address;

// (modelAddress, systemPrompt, optionsJson, pcmBytes)
// Single cactusComplete call: passes audio + inspection context together so Gemma 4
// responds directly without a separate transcription step. A second cactusComplete
// call on the same model after an audio pass crashes (audio KV state not fully reset
// by cactusReset), so we do everything in one shot.
// Per Cactus API: user content must be "" when pcmData is supplied.
String _runCactusCompleteWithAudio((int, String, String, Uint8List) args) {
  final model = Pointer<Void>.fromAddress(args.$1);
  final messagesJson = jsonEncode([
    {'role': 'system', 'content': args.$2},
    {'role': 'user', 'content': ''},
  ]);
  return cactusComplete(model, messagesJson, args.$3, null, null,
      pcmData: args.$4);
}

/// Directory name for the Gemma 4 E2B (INT4) variant weights folder.
const kGemma4E2bSlug = 'gemma-4-e2b-it-int4';

/// Directory name for the Gemma 4 E4B (INT8) variant weights folder.
const kGemma4E4bSlug = 'gemma-4-e4b-it-int8';

const _kModelSubdir = 'cactus';
const _kMaxResponseTokens = 256;

/// Recording config: PCM16 mono 16 kHz — exactly what Cactus transcription expects.
const _kSampleRate = 16000;

// VAD thresholds (PCM16 RMS values on scale 0–32767).
const _kVoiceThreshold = 800.0;   // RMS above this → speech detected
const _kSilenceThreshold = 400.0;  // RMS below this → silence
const _kMinSpeechMs = 400;         // ignore bursts shorter than this
const _kSilenceToTriggerMs = 1200; // silence duration required to end utterance

/// Tier 2: on-device LLM (Gemma 4 via Cactus FFI) with Cactus-native audio transcription.
///
/// Captures mic audio as raw PCM16 at 16 kHz mono, uses amplitude-based VAD to
/// detect utterance boundaries, then calls [cactusTranscribe] on the same model
/// handle used for [cactusComplete]. No external STT engine is involved.
///
/// Used when internet is unavailable on a capable device (≥4 GB RAM).
/// If the model directory is absent when [startListening] is called, a [StateError]
/// is emitted on [errorStream] and listening is aborted.
class CactusVoiceAgent implements VoiceAgent {
  CactusVoiceAgent(this._modelPath, this._tts);

  final String _modelPath;
  final FlutterTts _tts;

  /// Last path component — identifies the model variant (e.g. [kGemma4E4bSlug]).
  String get modelSlug => _modelPath.split(RegExp(r'[/\\]')).last;

  bool _listening = false;
  bool _ttsActive = false;   // true while TTS is speaking — suppresses VAD
  bool _processing = false;  // true during inference — prevents concurrent model calls
  bool _modelReady = false;
  CactusModelT? _model;
  InspectionSession? _currentSession;
  ConversationHistory? _history;

  // VAD state
  final _audioChunks = <Uint8List>[];
  bool _inSpeech = false;
  int _speechStartMs = 0;
  int _silenceStartMs = 0;
  StreamSubscription<Uint8List>? _audioSub;
  AudioRecorder? _recorder;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _processingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _actionController = StreamController<VoiceAction>.broadcast();
  final _audioLevelController = StreamController<double>.broadcast();

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
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  /// Returns the default on-device path for the given [modelSlug] (filename).
  static Future<String> defaultModelPath(String modelSlug) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_kModelSubdir/$modelSlug';
  }

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
    if (_listening) return;
    _listening = true;

    if (!_modelReady) {
      if (!Directory(_modelPath).existsSync()) {
        _listening = false;
        _errorController.add(StateError(
          'Model weights directory not found at $_modelPath. '
          'The model may still be downloading — check the home screen for progress.',
        ));
        return;
      }

      try {
        final address = await compute(_initCactusModel, _modelPath);
        _model = Pointer<Void>.fromAddress(address);
        _modelReady = true;
      } catch (e) {
        _listening = false;
        _errorController.add(e);
        return;
      }
    }

    _currentSession = session;
    _history = history;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);

    await _startRecording();
  }

  Future<void> _startRecording() async {
    final recorder = AudioRecorder();
    _recorder = recorder;

    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      _listening = false;
      _errorController.add(StateError('Microphone permission denied.'));
      return;
    }

    final stream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _kSampleRate,
        numChannels: 1,
        echoCancel: true,  // hardware AEC — cancels TTS output from mic input
        noiseSuppress: true,
      ),
    );

    _audioChunks.clear();
    _inSpeech = false;
    _speechStartMs = 0;
    _silenceStartMs = 0;

    _audioSub = stream.listen(
      _onAudioChunk,
      onError: (Object e) {
        if (_listening) _errorController.add(e);
      },
    );
  }

  void _onAudioChunk(Uint8List chunk) {
    if (!_listening || _ttsActive) {
      _audioLevelController.add(0.0);
      return;
    }

    final rms = _computeRms(chunk);
    // Normalize RMS (0-32767) to 0.0-1.0. 
    // Typical speech RMS is around 1000-5000.
    final normalized = (rms / 5000.0).clamp(0.0, 1.0);
    _audioLevelController.add(normalized);

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (!_inSpeech) {
      if (rms >= _kVoiceThreshold) {
        _inSpeech = true;
        _speechStartMs = nowMs;
        _silenceStartMs = 0;
        _audioChunks.clear();
        _audioChunks.add(chunk);
      }
      // discard silence chunks before any speech
    } else {
      _audioChunks.add(chunk);

      if (rms < _kSilenceThreshold) {
        if (_silenceStartMs == 0) _silenceStartMs = nowMs;

        final silenceDuration = nowMs - _silenceStartMs;
        final speechDuration = (_silenceStartMs > 0 ? _silenceStartMs : nowMs) - _speechStartMs;

        if (silenceDuration >= _kSilenceToTriggerMs &&
            speechDuration >= _kMinSpeechMs) {
          _inSpeech = false;
          _dispatchUtterance(Uint8List.fromList(
            _audioChunks.expand((c) => c).toList(),
          ));
          _audioChunks.clear();
          _silenceStartMs = 0;
        }
      } else {
        // reset silence timer on new speech
        _silenceStartMs = 0;
      }
    }
  }

  double _computeRms(Uint8List pcm16) {
    if (pcm16.length < 2) return 0;
    final bd = ByteData.sublistView(pcm16);
    double sum = 0;
    final samples = pcm16.length ~/ 2;
    for (var i = 0; i < samples; i++) {
      final s = bd.getInt16(i * 2, Endian.little).toDouble();
      sum += s * s;
    }
    return math.sqrt(sum / samples);
  }

  void _dispatchUtterance(Uint8List pcm) {
    final session = _currentSession;
    final history = _history;
    if (session == null || history == null || !_listening) return;
    _processUtterance(pcm, session, history);
  }

  Future<void> _processUtterance(
      Uint8List pcm, InspectionSession session, ConversationHistory history) async {
    final model = _model;
    if (model == null || _processing) return;
    _processing = true;
    _processingController.add(true);

    try {
      // Single cactusComplete call with audio + inspection context + prior history.
      // A second call after an audio pass crashes even after cactusReset — the audio
      // KV state is not fully cleared. So we respond directly to the audio in one shot.
      final systemPrompt = buildSystemPrompt(session, history);
      final optionsJson = jsonEncode({'max_tokens': _kMaxResponseTokens});
      final rawResponse = await compute(
        _runCactusCompleteWithAudio,
        (model.address, systemPrompt, optionsJson, pcm),
      );
      final (displayText, action) = _parseResponse(rawResponse);
      if (displayText.isEmpty) return;

      if (action != null) _actionController.add(action);

      _transcriptController.add(ConversationTurn.kAudioPlaceholder);
      history.addUser(ConversationTurn.kAudioPlaceholder);
      history.addAssistant(displayText);

      _responseController.add(displayText);

      // TTS output — gate VAD while speaking to prevent self-echo.
      _ttsActive = true;
      _inSpeech = false;
      _audioChunks.clear();
      final speakCompleter = Completer<void>();
      _tts.setCompletionHandler(() {
        if (!speakCompleter.isCompleted) speakCompleter.complete();
      });
      await _tts.speak(displayText);
      await speakCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
      _ttsActive = false;
    } catch (e) {
      debugPrint('CactusVoiceAgent: error processing utterance: $e');
      _errorController.add(e);
    } finally {
      _processing = false;
      _processingController.add(false);
    }
  }

  /// Parses the Cactus JSON response into display text and an optional action.
  /// Falls back to `(raw, null)` if the response is not valid JSON.
  static (String, VoiceAction?) _parseResponse(String raw) {
    try {
      final json = jsonDecode(raw.trim()) as Map<String, dynamic>;
      final text = (json['text'] as String? ?? '').trim();
      final actionJson = json['action'] as Map<String, dynamic>?;
      if (actionJson == null) return (text, null);
      final action = switch (actionJson['type'] as String?) {
        'start_new_inspection' => const StartNewInspection(),
        'save_session' => const SaveSession(),
        'record_observation' => RecordObservation(
            (actionJson['text'] as String? ?? '').trim()),
        'take_photo' => TakePhoto(
            description: actionJson['description'] as String?),
        'upload_floorplan' => const UploadFloorplan(),
        _ => null,
      };
      return (text, action);
    } catch (_) {
      return (raw.trim(), null);
    }
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    _ttsActive = false;
    _processing = false;
    _currentSession = null;
    _history = null;
    _inSpeech = false;
    _audioChunks.clear();
    _audioLevelController.add(0.0);
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder?.stop();
    _recorder = null;
    await _tts.stop();
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    final model = _model;
    if (model != null) {
      cactusDestroy(model);
      _model = null;
    }
    _modelReady = false;
    await _transcriptController.close();
    await _responseController.close();
    await _processingController.close();
    await _errorController.close();
    await _actionController.close();
    await _audioLevelController.close();
  }

  @visibleForTesting
  static String buildSystemPrompt(InspectionSession session, ConversationHistory history) {
    final lines = session.observations.map((o) {
      final photo = o.photoFileRef != null ? ' [photo: ${o.photoFileRef}]' : '';
      return '- ${o.timestamp.toIso8601String()}: ${o.text ?? '(no text)'}$photo';
    }).join('\n');

    return '''You are a fire inspection AI assistant helping a firefighter conduct a pre-incident survey. You are running offline on the inspector's device.
Keep responses brief (1-2 sentences).

Always respond in this exact JSON format:
{"text": "<your spoken reply>", "action": <action_or_null>}

Action types:
  Start new inspection: {"type": "start_new_inspection"}
  Save session:        {"type": "save_session"}
  Record observation:  {"type": "record_observation", "text": "<observation text>"}
  Request photo:       {"type": "take_photo", "description": "<what to photograph>"}
  Upload floorplan:    {"type": "upload_floorplan"}

When the user wants to start a new inspection, respond with start_new_inspection.
When the user wants to save or finish, respond with save_session.
When the inspector states a factual observation, respond with record_observation immediately.
When they ask to photograph something, respond with take_photo.
When they ask to upload or replace the floorplan, respond with upload_floorplan.
For questions or confirmations, set "action" to null.

Example: {"text": "Noted, blocked exit recorded.", "action": {"type": "record_observation", "text": "North exit blocked by storage equipment"}}

Inspection: ${session.name}
${lines.isEmpty ? 'No observations recorded yet.' : 'Existing observations:\n$lines'}${history.toSystemPromptBlock()}''';
  }
}
