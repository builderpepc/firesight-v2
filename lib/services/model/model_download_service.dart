import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StateNotifier;

import '../../core/constants.dart';
import '../voice/cactus_voice_agent.dart' show kGemma4E2bSlug;

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

/// ZIP downloaded; extracting GGUF from archive.
class ModelDownloadExtracting extends ModelDownloadStatus {
  const ModelDownloadExtracting();
}

/// Model file is present on disk and ready for inference.
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

/// Manages the lifecycle of downloading the Gemma 4 E2B GGUF model file.
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

  String get _destPath => '${_appDocsDir.path}/$_kCactusSubdir/$kGemma4E2bSlug';
  String get _zipTmpPath => '$_destPath.zip.tmp';

  /// Ensures the model is present, downloading it automatically if on WiFi.
  ///
  /// No-ops if already [ModelDownloadReady] or [ModelDownloadInProgress].
  /// Sets state to [ModelDownloadNeedsWifi] if connection is mobile-only.
  Future<void> ensureDownloaded() async {
    final s = state;
    if (s is ModelDownloadReady || s is ModelDownloadInProgress ||
        s is ModelDownloadExtracting) return;

    state = const ModelDownloadChecking();
    if (File(_destPath).existsSync()) {
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
    final dir = Directory('${_appDocsDir.path}/$_kCactusSubdir');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Resume support: if a partial .zip.tmp exists, send a Range header.
    final tmpFile = File(_zipTmpPath);
    final existingBytes = tmpFile.existsSync() ? tmpFile.lengthSync() : 0;
    final headers = existingBytes > 0
        ? <String, dynamic>{'Range': 'bytes=$existingBytes-'}
        : <String, dynamic>{};

    state = ModelDownloadInProgress(
      existingBytes > 0 ? null : 0.0,
      existingBytes,
      0,
    );

    _cancelToken = CancelToken();
    final dio = Dio();

    try {
      await dio.download(
        ModelUrls.gemma4E2bZip,
        _zipTmpPath,
        cancelToken: _cancelToken,
        deleteOnError: false,
        options: Options(
          headers: headers,
          receiveTimeout: null,
          sendTimeout: const Duration(seconds: 30),
        ),
        onReceiveProgress: (received, total) {
          final totalReceived = existingBytes + received;
          final fullTotal = total == -1 ? 0 : existingBytes + total;
          final progress = (fullTotal > 0) ? totalReceived / fullTotal : null;
          state = ModelDownloadInProgress(progress, totalReceived, fullTotal);
        },
      );

      state = const ModelDownloadExtracting();
      await _extractGguf();

      // Clean up the ZIP temp file.
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
    }
  }

  /// Extracts the first `.gguf` file found in [_zipTmpPath] to [_destPath].
  Future<void> _extractGguf() async {
    final inputStream = InputFileStream(_zipTmpPath);
    try {
      final archive = ZipDecoder().decodeStream(inputStream);
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name;
        if (!name.endsWith('.gguf')) continue;

        final outFile = File(_destPath);
        final outStream = OutputFileStream(outFile.path);
        try {
          file.writeContent(outStream);
        } finally {
          outStream.close();
        }
        return; // first .gguf found — done
      }
      throw StateError('No .gguf file found inside ZIP archive.');
    } finally {
      inputStream.close();
    }
  }
}
