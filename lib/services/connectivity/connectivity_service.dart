import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps connectivity_plus; exposes internet status stream.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  /// Stream of internet availability.
  Stream<bool> get isOnline => _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}
