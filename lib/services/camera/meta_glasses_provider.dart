import 'dart:typed_data';
import 'package:firesight/services/camera/camera_provider.dart';

/// Impl: Meta Ray-Ban glasses camera (Android only).
/// TODO(ios): Requires macOS contributor with Xcode to integrate the iOS SDK.
/// TODO(android): meta_wearables_dat disabled pending android_id plugin conflict resolution.
class MetaGlassesProvider implements CameraProvider {
  @override
  bool get isAvailable => false;

  @override
  Future<Uint8List> capturePhoto() async {
    throw UnimplementedError('MetaGlassesProvider not yet available — awaiting SDK conflict resolution');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
