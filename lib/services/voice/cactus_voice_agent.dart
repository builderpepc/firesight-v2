import 'dart:async';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/gemma4_downloader.dart';
import 'package:firesight/services/voice/voice_agent.dart';

export 'package:firesight/services/voice/gemma4_downloader.dart'
    show kGemma4E2bSlug, kGemma4E4bSlug;

const _kMaxResponseTokens = 256;
const _kListenFor = Duration(seconds: 30);
const _kPauseFor = Duration(seconds: 2);

/// Tier 2: on-device LLM (Gemma 4 via CactusLM) + native STT + native TTS.
///
/// Used when internet is unavailable on a capable device (≥4 GB RAM).
/// [modelSlug] selects [kGemma4E4bSlug] (≥6 GB, INT8) or [kGemma4E2bSlug]
/// (4–6 GB, INT4). Weights are downloaded from HuggingFace on first use.
class CactusVoiceAgent implements VoiceAgent {
  CactusVoiceAgent(
    this._cactus,
    this._stt,
    this._tts, {
    this.modelSlug = kGemma4E2bSlug,
  });

  final CactusLM _cactus;
  final SpeechToText _stt;
  final FlutterTts _tts;

  /// Hint slug that was passed to the constructor.
  final String modelSlug;

  bool _listening = false;
  bool _modelReady = false;
  String? _resolvedSlug;

  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  /// Emits `(progress, statusMessage)` during the initial model download.
  /// `progress` is 0.0–1.0 while downloading, or null for indeterminate steps.
  final _downloadProgressController =
      StreamController<(double?, String)>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  Stream<(double?, String)> get downloadProgressStream =>
      _downloadProgressController.stream;

  @override
  Future<void> startListening(InspectionSession session) async {
    if (_listening) return;
    _listening = true;

    if (!_modelReady) {
      try {
        _downloadProgressController.add((null, 'Checking model…'));
        final localSlug = await ensureGemma4Downloaded(
          modelSlug,
          onProgress: (progress, status) {
            _downloadProgressController.add((progress, status));
          },
        );

        if (localSlug == null) {
          _listening = false;
          _errorController.add(StateError(
            'Failed to download Gemma 4 model. '
            'Check your internet connection and try again.',
          ));
          return;
        }

        _resolvedSlug = localSlug;
        _downloadProgressController.add((null, 'Initializing model…'));
        await _cactus.initializeModel(
          params: CactusInitParams(model: localSlug, contextSize: 2048),
        );
        _modelReady = true;
        _downloadProgressController.add((1.0, 'Model ready'));
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

  /// Begins one STT listen cycle; re-invoked automatically after each response.
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

  /// Runs [utterance] through CactusLM and speaks the response via TTS.
  Future<void> _processUtterance(
      String utterance, InspectionSession session) async {
    try {
      final messages = buildMessages(session, utterance);
      final streamedResult = await _cactus.generateCompletionStream(
        messages: messages,
        params: CactusCompletionParams(
          model: _resolvedSlug ?? modelSlug,
          maxTokens: _kMaxResponseTokens,
        ),
      );

      final buffer = StringBuffer();
      await for (final token in streamedResult.stream) {
        buffer.write(token);
      }

      final response = buffer.toString().trim();
      if (response.isEmpty) return;

      _responseController.add(response);

      final speakCompleter = Completer<void>();
      _tts.setCompletionHandler(() {
        if (!speakCompleter.isCompleted) speakCompleter.complete();
      });
      await _tts.speak(response);
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
    _cactus.unload();
    _modelReady = false;
    _resolvedSlug = null;
    await _transcriptController.close();
    await _responseController.close();
    await _errorController.close();
    await _downloadProgressController.close();
  }

  /// Builds the CactusLM message list from [session] context and [utterance].
  @visibleForTesting
  static List<ChatMessage> buildMessages(
    InspectionSession session,
    String utterance,
  ) {
    return [
      ChatMessage(role: 'system', content: _buildSystemPrompt(session)),
      ChatMessage(role: 'user', content: utterance),
    ];
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
