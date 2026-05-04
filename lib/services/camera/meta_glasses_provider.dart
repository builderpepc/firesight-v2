import 'dart:typed_data';
import 'package:firesight/services/camera/camera_provider.dart';

/// Impl: Meta Ray-Ban glasses camera (Android only).
/// TODO(ios): Requires macOS contributor with Xcode to integrate the iOS SDK.
/// TODO(android): implement camera capture using meta_wearables_dat SDK.
class MetaGlassesProvider implements CameraProvider {
  @override
  bool get isAvailable => false;

  @override
  Future<Uint8List> capturePhoto() async {
    throw UnimplementedError('MetaGlassesProvider.capturePhoto: TODO — implement via meta_wearables_dat SDK');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
