import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_storage.dart';

/// Loads sessions through [SessionStorage] and writes them to a ZIP archive.
/// Storage-backend agnostic: works with the SQLite-backed storage as well as
/// any other implementation of the [SessionStorage] interface.
///
/// Archive layout per session:
///   `<sessionId>/session.json`        — full session JSON
///   `<sessionId>/photos/<filename>`   — referenced photo files (deduped)
class SessionExport {
  SessionExport(this._storage, {Future<Directory> Function()? tmpDirProvider})
      : _tmpDirProvider = tmpDirProvider ?? getTemporaryDirectory;

  final SessionStorage _storage;
  final Future<Directory> Function() _tmpDirProvider;

  /// Exports the given sessions to a ZIP file in the system temp directory.
  /// Sessions that no longer exist in storage are skipped silently;
  /// referenced photo files that are missing on disk are likewise skipped.
  Future<File> exportSessions(List<SessionMetadata> sessions) async {
    final archive = Archive();

    for (final meta in sessions) {
      final session = await _storage.loadSession(meta.id);
      if (session == null) continue;

      final sessionBytes = utf8.encode(jsonEncode(session.toJson()));
      archive.addFile(ArchiveFile(
        '${session.id}/session.json',
        sessionBytes.length,
        sessionBytes,
      ));

      final photoPaths = <String>{
        if (session.floorplanPath != null) session.floorplanPath!,
        ...session.observations
            .where((obs) => obs.photoFileRef != null)
            .map((obs) => obs.photoFileRef!),
        ...session.buildingDocuments.map((doc) => doc.filePath),
      };

      for (final path in photoPaths) {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(
          '${session.id}/photos/${basename(path)}',
          bytes.length,
          bytes,
        ));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final tmpDir = await _tmpDirProvider();
    final output = File(join(
      tmpDir.path,
      'firesight_export_${DateTime.now().millisecondsSinceEpoch}.zip',
    ));
    await output.writeAsBytes(zipBytes);
    return output;
  }
}
