import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:firesight/services/camera/camera_provider.dart';

/// Impl: Flutter camera package for phone camera.
class PhoneCameraProvider implements CameraProvider {
  PhoneCameraProvider(this._controller);

  final CameraController? _controller;

  @override
  bool get isAvailable => true;

  @override
  Future<Uint8List> capturePhoto() async {
    // TODO: Implement photo capture using camera package.
    // Initialize CameraController, capture XFile, convert to Uint8List.
    throw UnimplementedError('PhoneCameraProvider.capturePhoto: TODO');
  }

  @override
  Future<void> initialize() async {
    // TODO: Initialize camera controller.
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
  }
}
