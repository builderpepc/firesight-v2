import 'dart:typed_data';

/// Abstract camera provider interface.
abstract class CameraProvider {
  /// Returns true if this provider is available on current platform/device.
  bool get isAvailable;

  /// Captures a single photo and returns its raw bytes.
  Future<Uint8List> capturePhoto();

  Future<void> initialize();
  Future<void> dispose();
}
