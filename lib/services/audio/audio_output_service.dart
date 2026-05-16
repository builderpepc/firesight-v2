import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Manages real-time PCM audio output via SoLoud's buffer-streaming API.
///
/// Call [init] once on startup (safe to call repeatedly — no-ops if already
/// initialised). Feed incoming 24 kHz mono s16le PCM chunks via [addChunk];
/// a new SoLoud buffer stream is created automatically whenever audio arrives
/// after a gap (the previous stream closes when its buffer drains). Call
/// [stopPlayback] at session end to clean up any active stream.
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

  /// Feeds a raw PCM chunk into the active playback stream, creating a new
  /// stream if the previous one has already drained and closed.
  void addChunk(Uint8List bytes) {
    if (!SoLoud.instance.isInitialized) return;
    final h = _handle;
    final streamEnded = h == null || !SoLoud.instance.getIsValidVoiceHandle(h);
    if (streamEnded) _openStream();
    SoLoud.instance.addAudioDataStream(_stream!, bytes);
  }

  /// True while SoLoud still has buffered audio playing.
  bool get isPlaying {
    final h = _handle;
    return h != null &&
        SoLoud.instance.isInitialized &&
        SoLoud.instance.getIsValidVoiceHandle(h);
  }

  /// Signals end-of-data and stops any active playback stream.
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

  void _openStream() {
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
}
