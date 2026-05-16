import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../../core/constants.dart';
import '../voice/cactus_voice_agent.dart' show kGemma4E2bSlug;
import 'download_foreground_task.dart' show downloadTaskCallback;

const _kCactusSubdir = 'cactus';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Lifecycle state for the Gemma 4 E2B model download.
sealed class ModelDownloadStatus {
  const ModelDownloadStatus();
}

/// No download has been requested yet.
class ModelDownloadIdle extends ModelDownloadStatus {
  const ModelDownloadIdle();
}

/// Checking whether the model file already exists on disk.
class ModelDownloadChecking extends ModelDownloadStatus {
  const ModelDownloadChecking();
}

/// Model is absent but connectivity is not WiFi/ethernet; waiting for WiFi.
class ModelDownloadNeedsWifi extends ModelDownloadStatus {
  const ModelDownloadNeedsWifi();
}

/// ZIP archive is actively downloading.
class ModelDownloadInProgress extends ModelDownloadStatus {
  const ModelDownloadInProgress(this.progress, this.bytesReceived, this.totalBytes);

  /// 0.0–1.0, or null when total size is unknown (chunked without Content-Length).
  final double? progress;
  final int bytesReceived;
  final int totalBytes;
}

/// ZIP downloaded; extracting weight files from archive.
class ModelDownloadExtracting extends ModelDownloadStatus {
  const ModelDownloadExtracting();
}

/// Model weights directory is present on disk and ready for inference.
class ModelDownloadReady extends ModelDownloadStatus {
  const ModelDownloadReady();
}

/// Download or extraction failed, or was cancelled.
class ModelDownloadFailed extends ModelDownloadStatus {
  const ModelDownloadFailed(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the lifecycle of downloading the Gemma 4 E2B weight files.
///
/// The model is distributed as a ZIP archive containing individual `.weights`
/// files (Cactus native format). Extraction produces a directory of weight
/// files that [cactusInit] loads by directory path.
///
/// Call [ensureDownloaded] on app start or when Tier 2 is selected. The
/// notifier updates its [state] as the download progresses. Callers watch
/// the Riverpod provider derived from this notifier to drive UI.
class ModelDownloadNotifier extends StateNotifier<ModelDownloadStatus> {
  ModelDownloadNotifier(this._appDocsDir, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ModelDownloadIdle());

  final Directory _appDocsDir;
  final Connectivity _connectivity;
  CancelToken? _cancelToken;

  /// Directory where the extracted weight files live.
  String get _destDir => '${_appDocsDir.path}/$_kCactusSubdir/$kGemma4E2bSlug';

  /// Sentinel file written after a successful extraction.
  String get _sentinelPath => '$_destDir/.ready';

  String get _zipTmpPath => '$_destDir.zip.tmp';

  /// Ensures the model is present, downloading it automatically if on WiFi.
  ///
  /// No-ops if already [ModelDownloadReady] or [ModelDownloadInProgress].
  /// Sets state to [ModelDownloadNeedsWifi] if connection is mobile-only.
  Future<void> ensureDownloaded() async {
    final s = state;
    if (s is ModelDownloadReady || s is ModelDownloadInProgress ||
        s is ModelDownloadExtracting) return;

    state = const ModelDownloadChecking();
    if (File(_sentinelPath).existsSync()) {
      state = const ModelDownloadReady();
      return;
    }

    final result = await _connectivity.checkConnectivity();
    final hasUnmeteredConnection = result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);

    if (!hasUnmeteredConnection) {
      state = const ModelDownloadNeedsWifi();
      return;
    }

    await _download();
  }

  /// Starts download even on mobile data. Called from UI "Download anyway" action.
  Future<void> startDownloadOnMobile() async {
    final s = state;
    if (s is ModelDownloadReady || s is ModelDownloadInProgress ||
        s is ModelDownloadExtracting) return;
    await _download();
  }

  /// Cancels an active download. State → [ModelDownloadFailed].
  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
  }

  /// Resets state to [ModelDownloadIdle] then calls [ensureDownloaded].
  Future<void> retryDownload() async {
    state = const ModelDownloadIdle();
    await ensureDownloaded();
  }

  Future<void> _download() async {
    final cactusDir = Directory('${_appDocsDir.path}/$_kCactusSubdir');
    if (!cactusDir.existsSync()) cactusDir.createSync(recursive: true);

    // Always start fresh — Dio's download() opens files in write mode, not
    // append mode, so a Range-based resume would overwrite the tmp file with
    // only the tail of the ZIP, producing a corrupt archive.
    final tmpFile = File(_zipTmpPath);
    if (tmpFile.existsSync()) tmpFile.deleteSync();

    state = const ModelDownloadInProgress(0.0, 0, 0);

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Downloading Gemma 4 model',
      notificationText: 'Starting download… (4.4 GB)',
      callback: downloadTaskCallback,
    );

    _cancelToken = CancelToken();
    final dio = Dio();
    int lastNotifiedPct = -1;

    try {
      await dio.download(
        ModelUrls.gemma4E2bZip,
        _zipTmpPath,
        cancelToken: _cancelToken,
        deleteOnError: true,
        options: Options(
          receiveTimeout: null,
          sendTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          final fullTotal = total == -1 ? 0 : total;
          final progress = (fullTotal > 0) ? received / fullTotal : null;
          state = ModelDownloadInProgress(progress, received, fullTotal);

          // Update the foreground notification roughly once per percent.
          final pct = progress != null ? (progress * 100).toInt() : -1;
          if (pct != lastNotifiedPct) {
            lastNotifiedPct = pct;
            final mb = (received / 1024 / 1024).toStringAsFixed(0);
            final totalMb = fullTotal > 0
                ? ' / ${(fullTotal / 1024 / 1024).toStringAsFixed(0)} MB'
                : ' MB';
            final pctStr = pct >= 0 ? ' ($pct%)' : '';
            FlutterForegroundTask.updateService(
              notificationText: '$mb$totalMb$pctStr',
            );
          }
        },
      );

      state = const ModelDownloadExtracting();
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Extracting Gemma 4 model',
        notificationText: 'Unpacking weight files…',
      );
      await _extractAll();

      if (tmpFile.existsSync()) tmpFile.deleteSync();
      state = const ModelDownloadReady();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        state = const ModelDownloadFailed('Download cancelled.');
      } else {
        state = ModelDownloadFailed('Download failed: ${e.message}');
      }
    } catch (e) {
      state = ModelDownloadFailed('Download failed: $e');
    } finally {
      await FlutterForegroundTask.stopService();
    }
  }

  static const _zipChannel = MethodChannel('com.firesight.firesight/zip');

  /// Extracts all entries in [_zipTmpPath] to [_destDir] using the Android
  /// native ZipInputStream, then writes a sentinel so partial extractions
  /// are never mistaken for complete. The native implementation streams
  /// entry-by-entry with a 64 KB buffer — RAM usage is constant regardless
  /// of archive size.
  Future<void> _extractAll() async {
    final destDir = Directory(_destDir);
    if (destDir.existsSync()) destDir.deleteSync(recursive: true);
    destDir.createSync(recursive: true);

    await _zipChannel.invokeMethod<void>('extractZip', {
      'zipPath': _zipTmpPath,
      'destPath': _destDir,
    });

    // Write sentinel only after all entries are written.
    File(_sentinelPath).writeAsBytesSync([]);
  }
}
