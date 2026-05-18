import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around flutter_tts for audio summaries.
class TtsService {
  TtsService(this._flutterTts);

  final FlutterTts _flutterTts;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _ensureInitialized();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
