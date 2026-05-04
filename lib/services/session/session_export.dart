import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firesight/models/session_metadata.dart';

/// ZIP archive import/export via archive package.
class SessionExport {
  SessionExport(this._sessionsDir);

  final Directory _sessionsDir;

  /// Exports selected sessions to a ZIP file in the system temp directory.
  Future<File> exportSessions(List<SessionMetadata> sessions) async {
    final archive = Archive();
    for (final session in sessions) {
      final sessionDir = Directory('${_sessionsDir.path}/${session.id}');
      if (sessionDir.existsSync()) {
        for (final entity in sessionDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.replaceFirst(
                _sessionsDir.path + Platform.pathSeparator, '');
            final bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
          }
        }
      }
    }
    final zipBytes = ZipEncoder().encode(archive);
    final tmpDir = await getTemporaryDirectory();
    final output = File(
        '${tmpDir.path}/firesight_export_${DateTime.now().millisecondsSinceEpoch}.zip');
    await output.writeAsBytes(zipBytes);
    return output;
  }

  /// Imports sessions from a ZIP file into the sessions directory.
  /// Returns the list of imported session IDs.
  Future<List<String>> importSessions(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final importedIds = <String>[];
    for (final file in archive) {
      final outFile = File('${_sessionsDir.path}/${file.name}');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
      if (file.name.endsWith('session.json')) {
        final json =
            jsonDecode(utf8.decode(file.content as List<int>)) as Map<String, dynamic>;
        final id = json['id'] as String?;
        if (id != null) importedIds.add(id);
      }
    }
    return importedIds;
  }
}
