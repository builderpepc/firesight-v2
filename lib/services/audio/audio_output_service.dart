import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Manages real-time PCM audio output via SoLoud's buffer-streaming API.
///
/// Call [init] once on startup (safe to call repeatedly — no-ops if already
/// initialised). At the start of each agent session call [startPlayback], feed
/// incoming 24 kHz mono s16le PCM chunks via [addChunk], then call
/// [stopPlayback] when the session ends.
class AudioOutputService {
  AudioSource? _stream;
  SoundHandle? _handle;

  static const int _sampleRate = 24000;
  static const Channels _channels = Channels.mono;
  static const BufferType _format = BufferType.s16le;

  Future<void> init() async {
    if (SoLoud.instance.isInitialized) return;
    await SoLoud.instance.init(sampleRate: _sampleRate, channels: _channels);
  }

  /// Creates a new buffer stream and begins playback. Call once per session.
  Future<void> startPlayback() async {
    if (!SoLoud.instance.isInitialized) return;
    _stream = SoLoud.instance.setBufferStream(
      bufferingType: BufferingType.released,
      bufferingTimeNeeds: 0,
      sampleRate: _sampleRate,
      channels: _channels,
      format: _format,
    );
    // play() is synchronous in flutter_soloud 4.x.
    _handle = SoLoud.instance.play(_stream!);
  }

  /// Feeds a raw PCM chunk into the active playback stream.
  void addChunk(Uint8List bytes) {
    final s = _stream;
    if (s != null) SoLoud.instance.addAudioDataStream(s, bytes);
  }

  /// Signals end-of-data and stops the current playback stream.
  Future<void> stopPlayback() async {
    final s = _stream;
    final h = _handle;
    _stream = null;
    _handle = null;
    if (s == null || h == null) return;
    if (!SoLoud.instance.isInitialized) return;
    if (SoLoud.instance.getIsValidVoiceHandle(h)) {
      SoLoud.instance.setDataIsEnded(s);
      await SoLoud.instance.stop(h);
    }
  }
}
