import 'dart:async';
import 'package:cactus/cactus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

// Verify these slugs against `CactusLM().getModels()` before first deployment:
// https://huggingface.co/Cactus-Compute — E4B for ≥6 GB RAM, E2B otherwise.
const kGemma4E4bSlug = 'google/gemma-4-E4B-it';
const kGemma4E2bSlug = 'google/gemma-4-E2B-it';

const _kMaxResponseTokens = 256;
const _kListenFor = Duration(seconds: 30);
const _kPauseFor = Duration(seconds: 2);

/// Tier 2: on-device LLM (Gemma 4 via CactusLM) + native STT + native TTS.
///
/// Used when internet is unavailable on a capable device (≥4 GB RAM).
/// The [modelSlug] selects E4B (≥6 GB) or E2B (4–6 GB); defaults to E2B.
///
/// NOTE: Galaxy S22 cannot run Gemma 4 reliably. The [VoiceAgentService] tier
/// selector falls through to Tier 3 (NativeFallbackAgent) for such devices.
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
  final String modelSlug;

  bool _listening = false;
  bool _modelReady = false;

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
    if (_listening) return;
    _listening = true;

    if (!_modelReady) {
      try {
        await _cactus.initializeModel(
          params: CactusInitParams(model: modelSlug, contextSize: 2048),
        );
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
  Future<void> _processUtterance(String utterance, InspectionSession session) async {
    try {
      final messages = buildMessages(session, utterance);
      final streamedResult = await _cactus.generateCompletionStream(
        messages: messages,
        params: CactusCompletionParams(
          model: modelSlug,
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
    await _transcriptController.close();
    await _responseController.close();
    await _errorController.close();
  }

  /// Builds the CactusLM message list from [session] context and the [utterance].
  /// Exposed for unit testing.
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
