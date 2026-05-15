import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:firesight/services/model/model_download_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

/// Builds a notifier wired to [mockConn] so tests avoid real platform channels.
ModelDownloadNotifier _notifier(
  Directory dir,
  _MockConnectivity mockConn,
) =>
    ModelDownloadNotifier(dir, connectivity: mockConn);

void main() {
  late Directory tempDir;
  late _MockConnectivity mockConn;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firesight_model_test_');
    mockConn = _MockConnectivity();
    // Default: report WiFi so most tests proceed to download stage.
    when(() => mockConn.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  group('ModelDownloadNotifier', () {
    test('initial state is ModelDownloadIdle', () {
      final n = _notifier(tempDir, mockConn);
      expect(n.state, isA<ModelDownloadIdle>());
    });

    test('ensureDownloaded → Ready when model file already exists', () async {
      final modelDir = Directory('${tempDir.path}/cactus/gemma-4-e2b-it-int4')
        ..createSync(recursive: true);
      File('${modelDir.path}/.ready').writeAsBytesSync([]);

      final n = _notifier(tempDir, mockConn);
      await n.ensureDownloaded();

      expect(n.state, isA<ModelDownloadReady>());
      // Must NOT have called checkConnectivity since file was already present.
      verifyNever(() => mockConn.checkConnectivity());
    });

    test('ensureDownloaded is a no-op when already Ready', () async {
      final n = _notifier(tempDir, mockConn);
      n.state = const ModelDownloadReady();

      await n.ensureDownloaded();
      // No connectivity check needed.
      verifyNever(() => mockConn.checkConnectivity());
      expect(n.state, isA<ModelDownloadReady>());
    });

    test('ensureDownloaded → NeedsWifi when connection is mobile', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final n = _notifier(tempDir, mockConn);
      await n.ensureDownloaded();

      expect(n.state, isA<ModelDownloadNeedsWifi>());
    });

    test('ensureDownloaded → NeedsWifi when offline', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      final n = _notifier(tempDir, mockConn);
      await n.ensureDownloaded();

      expect(n.state, isA<ModelDownloadNeedsWifi>());
    });

    test('ensureDownloaded transitions through Checking before NeedsWifi',
        () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final states = <ModelDownloadStatus>[];
      final n = _notifier(tempDir, mockConn);
      n.addListener((s) => states.add(s));

      await n.ensureDownloaded();

      expect(states.any((s) => s is ModelDownloadChecking), isTrue,
          reason: 'Must pass through Checking state before reporting NeedsWifi');
    });

    test('cancelDownload does not throw when no download is active', () {
      final n = _notifier(tempDir, mockConn);
      expect(() => n.cancelDownload(), returnsNormally);
    });

    test('retryDownload resets to Idle then re-checks', () async {
      when(() => mockConn.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      final n = _notifier(tempDir, mockConn);
      n.state = const ModelDownloadFailed('previous error');

      final states = <ModelDownloadStatus>[];
      n.addListener((s) => states.add(s));

      await n.retryDownload();

      // addListener fires immediately with the current state (Failed), so
      // Idle appears as the second emitted state after retryDownload resets.
      expect(states.any((s) => s is ModelDownloadIdle), isTrue,
          reason: 'retryDownload must reset to Idle before re-checking');
      expect(n.state, isNot(isA<ModelDownloadFailed>()),
          reason: 'Must not end in Failed state after retry attempt');
    });

    test('notifier construction does not delete existing zip.tmp', () {
      // A stale .zip.tmp from a previous session must survive construction —
      // it is deleted only when a fresh _download() run starts.
      final cactusDir = Directory('${tempDir.path}/cactus')..createSync();
      final tmpFile =
          File('${cactusDir.path}/gemma-4-e2b-it-int4.zip.tmp');
      tmpFile.writeAsBytesSync(List.filled(1024, 0));

      _notifier(tempDir, mockConn); // construction must not touch the file
      expect(tmpFile.existsSync(), isTrue);
    });
  });

  group('ModelDownloadStatus sealed class', () {
    test('ModelDownloadIdle', () {
      expect(const ModelDownloadIdle(), isA<ModelDownloadStatus>());
    });

    test('ModelDownloadChecking', () {
      expect(const ModelDownloadChecking(), isA<ModelDownloadStatus>());
    });

    test('ModelDownloadNeedsWifi', () {
      expect(const ModelDownloadNeedsWifi(), isA<ModelDownloadStatus>());
    });

    test('ModelDownloadExtracting', () {
      expect(const ModelDownloadExtracting(), isA<ModelDownloadStatus>());
    });

    test('ModelDownloadReady', () {
      expect(const ModelDownloadReady(), isA<ModelDownloadStatus>());
    });

    test('ModelDownloadInProgress carries fields', () {
      const s = ModelDownloadInProgress(0.42, 420, 1000);
      expect(s.progress, closeTo(0.42, 0.001));
      expect(s.bytesReceived, 420);
      expect(s.totalBytes, 1000);
    });

    test('ModelDownloadInProgress progress is null when total unknown', () {
      const s = ModelDownloadInProgress(null, 100, 0);
      expect(s.progress, isNull);
    });

    test('ModelDownloadFailed carries message', () {
      const s = ModelDownloadFailed('network error');
      expect(s.message, 'network error');
    });
  });
}
