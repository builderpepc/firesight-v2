import 'dart:io';
import 'package:flutter/services.dart';

const _kChannel = 'com.firesight.firesight/device';

/// Queries hardware capabilities needed for voice-agent tier selection.
class DeviceCapabilityService {
  const DeviceCapabilityService();

  /// Total physical RAM in GB, rounded down to the nearest integer.
  ///
  /// Returns `null` when the platform does not support the query (e.g. iOS
  /// before a native channel is wired, or desktop). Callers should treat
  /// `null` as "unknown / low-power" and select Tier 3.
  Future<int?> totalRamGb() async {
    if (!Platform.isAndroid) return null;
    try {
      const channel = MethodChannel(_kChannel);
      final totalMb = await channel.invokeMethod<int>('getTotalRamMb');
      if (totalMb == null) return null;
      return totalMb ~/ 1024;
    } on PlatformException {
      return null;
    }
  }
}
