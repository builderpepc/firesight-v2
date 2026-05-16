import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';

import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_export.dart';
import 'package:firesight/services/session/session_storage.dart';

class _MockSessionStorage extends Mock implements SessionStorage {}

void main() {
  late Directory tempDir;
  late _MockSessionStorage storage;
  late SessionExport export;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firesight_export_test');
    storage = _MockSessionStorage();
    export = SessionExport(storage, tmpDirProvider: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writePhoto(String name, String contents) async {
    final f = File(join(tempDir.path, name));
    await f.writeAsString(contents);
    return f;
  }

  Map<String, ArchiveFile> entriesByName(Archive archive) {
    return {for (final f in archive) f.name: f};
  }

  test('exportSessions writes session.json and photo files into the archive',
      () async {
    final photo = await writePhoto('photo.jpg', 'photo-bytes');
    final floorplan = await writePhoto('floorplan.png', 'floorplan-bytes');
    final session = InspectionSession(
      id: 'session-1',
      name: 'Warehouse',
      createdAt: DateTime(2026, 5, 9, 10),
      updatedAt: DateTime(2026, 5, 9, 11),
      floorplanPath: floorplan.path,
      observations: [
        Observation(
          id: 'obs-1',
          timestamp: DateTime(2026, 5, 9, 10, 30),
          text: 'Blocked extinguisher',
          photoFileRef: photo.path,
        ),
      ],
    );

    when(() => storage.loadSession('session-1'))
        .thenAnswer((_) async => session);

    final meta = SessionMetadata(
      id: session.id,
      name: session.name,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    final outFile = await export.exportSessions([meta]);

    expect(await outFile.exists(), isTrue);

    final archive = ZipDecoder().decodeBytes(await outFile.readAsBytes());
    final entries = entriesByName(archive);

    expect(entries, contains('session-1/session.json'));
    expect(entries, contains('session-1/photos/photo.jpg'));
    expect(entries, contains('session-1/photos/floorplan.png'));

    final jsonBytes = entries['session-1/session.json']!.content as List<int>;
    final decoded =
        jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
    expect(decoded['id'], 'session-1');
    expect(decoded['name'], 'Warehouse');

    final photoBytes =
        entries['session-1/photos/photo.jpg']!.content as List<int>;
    expect(utf8.decode(photoBytes), 'photo-bytes');
  });

  test('exportSessions skips sessions that are missing in storage', () async {
    when(() => storage.loadSession('missing')).thenAnswer((_) async => null);

    final meta = SessionMetadata(
      id: 'missing',
      name: 'gone',
      createdAt: DateTime(2026, 5, 9),
      updatedAt: DateTime(2026, 5, 9),
    );

    final outFile = await export.exportSessions([meta]);
    final archive = ZipDecoder().decodeBytes(await outFile.readAsBytes());
    expect(archive.files, isEmpty);
  });

  test('exportSessions skips referenced photo files that do not exist on disk',
      () async {
    final session = InspectionSession(
      id: 'session-2',
      name: 'No Photo',
      createdAt: DateTime(2026, 5, 9),
      updatedAt: DateTime(2026, 5, 9),
      floorplanPath: '/tmp/does-not-exist-${DateTime.now().microsecondsSinceEpoch}.png',
    );

    when(() => storage.loadSession('session-2'))
        .thenAnswer((_) async => session);

    final meta = SessionMetadata(
      id: session.id,
      name: session.name,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    final outFile = await export.exportSessions([meta]);

    final archive = ZipDecoder().decodeBytes(await outFile.readAsBytes());
    final entries = entriesByName(archive);
    expect(entries, contains('session-2/session.json'));
    expect(
      entries.keys.where((k) => k.startsWith('session-2/photos/')),
      isEmpty,
    );
  });

  test('exportSessions deduplicates photos referenced multiple times',
      () async {
    final photo = await writePhoto('shared.jpg', 'shared-bytes');
    final session = InspectionSession(
      id: 'session-3',
      name: 'Shared photo',
      createdAt: DateTime(2026, 5, 9),
      updatedAt: DateTime(2026, 5, 9),
      floorplanPath: photo.path,
      observations: [
        Observation(
          id: 'a',
          timestamp: DateTime(2026, 5, 9, 9, 30),
          photoFileRef: photo.path,
        ),
        Observation(
          id: 'b',
          timestamp: DateTime(2026, 5, 9, 9, 45),
          photoFileRef: photo.path,
        ),
      ],
    );
    when(() => storage.loadSession('session-3'))
        .thenAnswer((_) async => session);

    final meta = SessionMetadata(
      id: session.id,
      name: session.name,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
    final outFile = await export.exportSessions([meta]);

    final archive = ZipDecoder().decodeBytes(await outFile.readAsBytes());
    final entries = entriesByName(archive);
    final photoEntries =
        entries.keys.where((k) => k.startsWith('session-3/photos/')).toList();
    expect(photoEntries, ['session-3/photos/shared.jpg']);
  });
}
