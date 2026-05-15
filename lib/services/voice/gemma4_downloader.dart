import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Hint slugs passed by callers to select which Gemma 4 variant to use.
/// These are NOT file names — they select which HuggingFace zip to fetch.
const kGemma4E2bSlug = 'gemma4-e2b'; // 2 B params, INT4 — requires ≥4 GB RAM
const kGemma4E4bSlug = 'gemma4-e4b'; // 2 B params, INT8 — requires ≥6 GB RAM

// Direct HuggingFace download URLs. The Cactus Supabase registry (Flutter SDK
// v1.3.0) does not include Gemma 4, so we bypass it entirely.
const _kGemma4E2bHfUrl =
    'https://huggingface.co/Cactus-Compute/gemma-4-E2B-it/resolve/main/weights/gemma-4-e2b-it-int4.zip';
const _kGemma4E2bLocalSlug = 'gemma4-e2b-it-int4';

// INT8 variant is used for the E4B hint (higher quality on devices with ≥6 GB).
const _kGemma4E4bHfUrl =
    'https://huggingface.co/Cactus-Compute/gemma-4-E2B-it/resolve/main/weights/gemma-4-e2b-it-int8.zip';
const _kGemma4E4bLocalSlug = 'gemma4-e2b-it-int8';

typedef Gemma4ProgressCallback = void Function(double? progress, String status);

/// Ensures Gemma 4 weights for [modelHint] are present on disk.
///
/// Downloads from HuggingFace the first time (2–4 GB). Subsequent calls
/// return immediately if the model directory already has files.
///
/// Returns the local slug (directory name under `models/`) on success,
/// or null if the download or extraction fails.
Future<String?> ensureGemma4Downloaded(
  String modelHint, {
  Gemma4ProgressCallback? onProgress,
}) async {
  final useE4b = modelHint == kGemma4E4bSlug;
  final url = useE4b ? _kGemma4E4bHfUrl : _kGemma4E2bHfUrl;
  final localSlug = useE4b ? _kGemma4E4bLocalSlug : _kGemma4E2bLocalSlug;

  final appDocDir = await getApplicationDocumentsDirectory();
  final modelDir = Directory('${appDocDir.path}/models/$localSlug');

  if (await _dirHasFiles(modelDir)) {
    debugPrint('ensureGemma4Downloaded: $localSlug already on disk');
    return localSlug;
  }

  onProgress?.call(null, 'Downloading Gemma 4 model from HuggingFace…');
  debugPrint('ensureGemma4Downloaded: fetching $localSlug');

  try {
    await modelDir.create(recursive: true);
    final tempZip = File('${appDocDir.path}/.tmp_$localSlug.zip');

    try {
      await _downloadFile(url, tempZip, onProgress: onProgress);
      onProgress?.call(null, 'Extracting model files…');
      await _extractStrippingRoot(tempZip, modelDir);
    } finally {
      if (await tempZip.exists()) await tempZip.delete();
    }

    if (!await _dirHasFiles(modelDir)) {
      throw StateError('Extraction produced no files in ${modelDir.path}');
    }

    debugPrint('ensureGemma4Downloaded: $localSlug ready at ${modelDir.path}');
    return localSlug;
  } catch (e) {
    debugPrint('ensureGemma4Downloaded: failed for $localSlug: $e');
    try { await modelDir.delete(recursive: true); } catch (_) {}
    return null;
  }
}

Future<bool> _dirHasFiles(Directory dir) async {
  if (!await dir.exists()) return false;
  return !(await dir.list().isEmpty);
}

Future<void> _downloadFile(
  String url,
  File dest, {
  Gemma4ProgressCallback? onProgress,
}) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }

    final total = response.contentLength;
    var received = 0;
    final sink = dest.openWrite();

    try {
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final receivedMb = (received / 1e6).toStringAsFixed(0);
          final totalMb = (total / 1e6).toStringAsFixed(0);
          onProgress?.call(
            received / total,
            'Downloading $receivedMb / $totalMb MB',
          );
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  } finally {
    client.close();
  }
}

/// Extracts [zipFile] into [targetDir], stripping a single root folder if
/// the zip contains exactly one top-level directory (matching Cactus behaviour).
Future<void> _extractStrippingRoot(File zipFile, Directory targetDir) async {
  final tempExtract = Directory(
    '${targetDir.parent.path}/.tmp_extract_${targetDir.uri.pathSegments.last}',
  );
  try {
    await tempExtract.create(recursive: true);
    await extractFileToDisk(zipFile.path, tempExtract.path);

    final topEntries = await tempExtract.list().toList();
    final topDirs = topEntries.whereType<Directory>().toList();
    final topFiles = topEntries.whereType<File>().toList();

    // If the zip had a single root folder, strip it so files land directly in targetDir.
    final sourceDir = (topFiles.isEmpty && topDirs.length == 1)
        ? topDirs.first
        : tempExtract;

    await for (final entry in sourceDir.list()) {
      final name = entry.uri.pathSegments.last;
      if (name.isEmpty) continue;
      await entry.rename('${targetDir.path}/$name');
    }
  } finally {
    if (await tempExtract.exists()) await tempExtract.delete(recursive: true);
  }
}
