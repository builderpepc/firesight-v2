import 'package:flutter_tts/flutter_tts.dart';

/// Thin wrapper around flutter_tts for audio summaries.
class TtsService {
  TtsService(this._flutterTts);

  final FlutterTts _flutterTts;

  Future<void> speak(String text) async {
    // TODO: Configure voice, language, rate via flutter_tts.
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
