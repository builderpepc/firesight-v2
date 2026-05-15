import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/cactus.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Directory name for the Gemma 4 E2B (INT4) variant weights folder.
const kGemma4E2bSlug = 'gemma-4-e2b-it-int4';

/// Directory name for the Gemma 4 E4B (INT8) variant weights folder.
const kGemma4E4bSlug = 'gemma-4-e4b-it-int8';

const _kModelSubdir = 'cactus';
const _kMaxResponseTokens = 256;
const _kListenFor = Duration(seconds: 30);
const _kPauseFor = Duration(seconds: 2);

/// Tier 2: on-device LLM (Gemma 4 via Cactus FFI) + native STT + native TTS.
///
/// Used when internet is unavailable on a capable device (≥4 GB RAM).
/// [_modelPath] is the absolute path to the Cactus weights directory. If the
/// directory is absent when [startListening] is called, a [StateError] is emitted on
/// [errorStream] and listening is aborted. Model download is deferred to a
/// separate flow — this agent only runs inference.
class CactusVoiceAgent implements VoiceAgent {
  CactusVoiceAgent(this._modelPath, this._stt, this._tts);

  final String _modelPath;
  final SpeechToText _stt;
  final FlutterTts _tts;

  /// Last path component — identifies the model variant (e.g. [kGemma4E4bSlug]).
  String get modelSlug => _modelPath.split(RegExp(r'[/\\]')).last;

  bool _listening = false;
  bool _modelReady = false;
  CactusModelT? _model;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  /// Returns the default on-device path for the given [modelSlug] (filename).
  static Future<String> defaultModelPath(String modelSlug) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_kModelSubdir/$modelSlug';
  }

  @override
  Future<void> startListening(InspectionSession session) async {
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
        _model = cactusInit(_modelPath, null, false);
        _modelReady = true;
      } catch (e) {
        _listening = false;
        _errorController.add(e);
        return;
      }
    }

    final available = await _stt.initialize(
      onError: (error) {
        _errorController.add(StateError('STT error: ${error.errorMsg}'));
      },
    );
    if (!available) {
      _listening = false;
      _errorController.add(
        StateError('Speech recognition not available on this device.'),
      );
      return;
    }

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);

    _startListenCycle(session);
  }

  void _startListenCycle(InspectionSession session) {
    if (!_listening) return;

    _stt.listen(
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        if (text.isEmpty) {
          _startListenCycle(session);
          return;
        }

        _transcriptController.add(text);
        await _processUtterance(text, session);
        _startListenCycle(session);
      },
      listenFor: _kListenFor,
      pauseFor: _kPauseFor,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: false,
      ),
    );
  }

  Future<void> _processUtterance(
      String utterance, InspectionSession session) async {
    final model = _model;
    if (model == null) return;

    try {
      final messagesJson = buildMessages(session, utterance);
      final optionsJson = jsonEncode({'max_tokens': _kMaxResponseTokens});
      final response = cactusComplete(model, messagesJson, optionsJson, null, null);
      final trimmed = response.trim();
      if (trimmed.isEmpty) return;

      _responseController.add(trimmed);

      final speakCompleter = Completer<void>();
      _tts.setCompletionHandler(() {
        if (!speakCompleter.isCompleted) speakCompleter.complete();
      });
      await _tts.speak(trimmed);
      await speakCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );
    } catch (e) {
      debugPrint('CactusVoiceAgent: error processing utterance: $e');
      _errorController.add(e);
    }
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    await _stt.stop();
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
    await _errorController.close();
  }

  /// Builds the Cactus message JSON from [session] context and [utterance].
  ///
  /// Returns a JSON-encoded list: `[{"role":"system","content":"..."},{"role":"user","content":"..."}]`
  @visibleForTesting
  static String buildMessages(InspectionSession session, String utterance) {
    return jsonEncode([
      {'role': 'system', 'content': _buildSystemPrompt(session)},
      {'role': 'user', 'content': utterance},
    ]);
  }

  static String _buildSystemPrompt(InspectionSession session) {
    final lines = session.observations.map((o) {
      final photo = o.photoFileRef != null ? ' [photo: ${o.photoFileRef}]' : '';
      return '- ${o.timestamp.toIso8601String()}: ${o.text ?? '(no text)'}$photo';
    }).join('\n');

    return '''You are a fire inspection AI assistant helping a firefighter conduct a pre-incident survey. You are running offline on the inspector's device.
Listen to the inspector. If they make an observation, confirm you noted it concisely.
If they ask a question, answer it based on the existing inspection context.
Keep responses brief (1-2 sentences).

Inspection: ${session.name}
${lines.isEmpty ? 'No observations recorded yet.' : 'Existing observations:\n$lines'}''';
  }
}
