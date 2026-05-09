import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/session/local_session_storage.dart';

void main() {
  late Directory tempDir;
  late LocalSessionStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firesight_session_test');
    storage = LocalSessionStorage(tempDir.path);
    await storage.ensureInitialized();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SessionStorage', () {
    test('listSessions returns sessions ordered by newest created first',
        () async {
      final older = InspectionSession(
        id: 'older-session',
        name: 'Older Session',
        createdAt: DateTime(2026, 5, 9, 10),
        updatedAt: DateTime(2026, 5, 9, 10),
      );
      final newer = InspectionSession(
        id: 'newer-session',
        name: 'Newer Session',
        createdAt: DateTime(2030, 5, 9, 12),
        updatedAt: DateTime(2030, 5, 9, 12),
      );

      await storage.saveSession(older);
      await storage.saveSession(newer);

      final sessions = await storage.listSessions();

      expect(sessions.map((session) => session.id).first, 'newer-session');
      expect(sessions.map((session) => session.id), contains(older.id));
    });

    test('saveSession stores notes and image references for later reload',
        () async {
      final sourceImage = File('${tempDir.path}/source.jpg');
      await sourceImage.writeAsString('fake-image-bytes');
      final storedImagePath = await storage.saveImage(sourceImage.path);

      final session = InspectionSession(
        id: 'session-with-observation',
        name: 'Session With Observation',
        createdAt: DateTime(2026, 5, 9, 9),
        updatedAt: DateTime(2026, 5, 9, 9),
        inspectorId: 'Inspector Lee',
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            text: 'North stairwell blocked',
            photoFileRef: storedImagePath,
          ),
        ],
      );

      await storage.saveSession(session);
      final loaded = await storage.loadSession(session.id);

      expect(loaded, isNotNull);
      expect(loaded!.inspectorId, 'Inspector Lee');
      expect(loaded.observations.single.text, 'North stairwell blocked');
      expect(loaded.observations.single.photoFileRef, storedImagePath);
      expect(File(storedImagePath).existsSync(), isTrue);
    });

    test('saveSession migrates external image paths into local app storage',
        () async {
      final externalDir =
          await Directory.systemTemp.createTemp('firesight_external_photo');
      addTearDown(() async {
        if (await externalDir.exists()) {
          await externalDir.delete(recursive: true);
        }
      });

      final externalImage = File('${externalDir.path}/camera.jpg');
      await externalImage.writeAsString('temp-camera-file');

      final session = InspectionSession(
        id: 'migrate-images',
        name: 'Migrate Images',
        createdAt: DateTime(2026, 5, 9, 9),
        updatedAt: DateTime(2026, 5, 9, 9),
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            text: 'Saved from previous session',
            photoFileRef: externalImage.path,
          ),
        ],
      );

      await storage.saveSession(session);
      final loaded = await storage.loadSession(session.id);

      expect(loaded, isNotNull);
      expect(
          loaded!.observations.single.photoFileRef, isNot(externalImage.path));
      expect(
        loaded.observations.single.photoFileRef,
        contains('${Platform.pathSeparator}photos${Platform.pathSeparator}'),
      );
      expect(
        File(loaded.observations.single.photoFileRef!).existsSync(),
        isTrue,
      );
    });

    test('loadSession migrates legacy external image paths into local storage',
        () async {
      final externalDir =
          await Directory.systemTemp.createTemp('firesight_legacy_photo');
      addTearDown(() async {
        if (await externalDir.exists()) {
          await externalDir.delete(recursive: true);
        }
      });

      final externalImage = File('${externalDir.path}/legacy.jpg');
      await externalImage.writeAsString('legacy-temp-camera-file');

      final sessionDir = Directory('${tempDir.path}/sessions/legacy-session');
      await sessionDir.create(recursive: true);
      final legacySession = InspectionSession(
        id: 'legacy-session',
        name: 'Legacy Session',
        createdAt: DateTime(2026, 5, 9, 9),
        updatedAt: DateTime(2026, 5, 9, 9),
        floorplanPath: externalImage.path,
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            text: 'Legacy observation',
            photoFileRef: externalImage.path,
          ),
        ],
      );
      await File('${sessionDir.path}/session.json')
          .writeAsString(jsonEncode(legacySession.toJson()));

      final loaded = await storage.loadSession('legacy-session');

      expect(loaded, isNotNull);
      expect(loaded!.floorplanPath, isNot(externalImage.path));
      expect(
          loaded.observations.single.photoFileRef, isNot(externalImage.path));
      expect(
        loaded.floorplanPath,
        contains('${Platform.pathSeparator}photos${Platform.pathSeparator}'),
      );
      expect(
        loaded.observations.single.photoFileRef,
        contains('${Platform.pathSeparator}photos${Platform.pathSeparator}'),
      );
    });

    test('deleteSession removes directory and stored assets', () async {
      final sourceImage = File('${tempDir.path}/source.jpg');
      await sourceImage.writeAsString('fake-image-bytes');
      final storedImagePath = await storage.saveImage(sourceImage.path);

      final session = InspectionSession(
        id: 'delete-me',
        name: 'Delete Me',
        createdAt: DateTime(2026, 5, 9, 9),
        updatedAt: DateTime(2026, 5, 9, 9),
        floorplanPath: storedImagePath,
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            photoFileRef: storedImagePath,
          ),
        ],
      );

      await storage.saveSession(session);
      await storage.deleteSession(session.id);

      expect(await storage.loadSession(session.id), isNull);
      expect(File(storedImagePath).existsSync(), isFalse);
    });

    test('saveSession stores relative paths in JSON but returns absolute paths on load',
        () async {
      final sourceImage = File('${tempDir.path}/source.jpg');
      await sourceImage.writeAsString('fake-image-bytes');
      final storedImagePath = await storage.saveImage(sourceImage.path);

      final session = InspectionSession(
        id: 'relative-path-test',
        name: 'Relative Path Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        floorplanPath: storedImagePath,
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime.now(),
            text: 'Test relative path',
            photoFileRef: storedImagePath,
          ),
        ],
      );

      await storage.saveSession(session);

      // Manually read the file to check the JSON content
      final sessionFile =
          File('${tempDir.path}/sessions/relative-path-test/session.json');
      final json =
          jsonDecode(await sessionFile.readAsString()) as Map<String, dynamic>;

      final String? floorplanPathInJson = json['floorplan_path'];
      final List<dynamic> observationsInJson = json['observations'];
      final String? photoFileRefInJson = observationsInJson[0]['photo_file_ref'];

      expect(floorplanPathInJson, isNotNull);
      expect(File(floorplanPathInJson!).isAbsolute, isFalse);
      expect(photoFileRefInJson, isNotNull);
      expect(File(photoFileRefInJson!).isAbsolute, isFalse);

      // Load and check absolute path
      final loaded = await storage.loadSession('relative-path-test');
      expect(loaded!.floorplanPath, storedImagePath);
      expect(loaded.observations.single.photoFileRef, storedImagePath);
    });
  });
}
