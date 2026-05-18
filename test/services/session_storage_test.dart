import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/services/session/local_session_storage.dart';

void main() {
  late Directory tempDir;
  late LocalSessionStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firesight_local_storage');
    storage = LocalSessionStorage(tempDir.path);
    await storage.ensureInitialized();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  InspectionSession buildSession({
    required String id,
    String name = 'Session',
    DateTime? createdAt,
    DateTime? updatedAt,
    String? zipCode,
    String? buildingType,
    String? status,
    String? inspectorId,
    String? riskLevel,
    String? floorplanPath,
    List<Observation> observations = const [],
  }) {
    final now = DateTime(2026, 5, 9, 10);
    return InspectionSession(
      id: id,
      name: name,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      zipCode: zipCode,
      buildingType: buildingType,
      status: status,
      inspectorId: inspectorId,
      riskLevel: riskLevel,
      floorplanPath: floorplanPath,
      observations: observations,
    );
  }

  Future<File> writeTempPhoto(String name, String contents) async {
    final external = await Directory.systemTemp.createTemp('firesight_photo_src');
    addTearDown(() async {
      if (await external.exists()) await external.delete(recursive: true);
    });
    final f = File(join(external.path, name));
    await f.writeAsString(contents);
    return f;
  }

  group('listSessions', () {
    test('returns sessions ordered by updatedAt desc', () async {
      await storage.saveSession(buildSession(
        id: 'older',
        updatedAt: DateTime(2026, 5, 9, 10),
      ));
      await storage.saveSession(buildSession(
        id: 'newer',
        updatedAt: DateTime(2026, 5, 10, 8),
      ));

      final list = await storage.listSessions();
      expect(list.map((m) => m.id), ['newer', 'older']);
    });

    test('filters by metadata fields', () async {
      await storage.saveSession(buildSession(
        id: 'a',
        zipCode: '10001',
        buildingType: 'hospital',
        status: 'open',
      ));
      await storage.saveSession(buildSession(
        id: 'b',
        zipCode: '10001',
        buildingType: 'school',
        status: 'closed',
      ));
      await storage.saveSession(buildSession(
        id: 'c',
        zipCode: '20002',
        buildingType: 'hospital',
        status: 'open',
      ));

      final byZip = await storage.listSessions(zipCode: '10001');
      expect(byZip.map((m) => m.id).toSet(), {'a', 'b'});

      final byZipAndType =
          await storage.listSessions(zipCode: '10001', buildingType: 'hospital');
      expect(byZipAndType.map((m) => m.id), ['a']);
    });
  });

  group('save / load round-trip', () {
    test('persists conversation history', () async {
      final history = ConversationHistory();
      history.addUser('Hello agent');
      history.addAssistant('Hello inspector');

      final session = buildSession(
        id: 'history-test',
      ).copyWith(history: history);

      await storage.saveSession(session);
      final loaded = await storage.loadSession('history-test');

      expect(loaded, isNotNull);
      expect(loaded!.history.turns, hasLength(2));
      expect(loaded.history.turns[0].role, 'user');
      expect(loaded.history.turns[0].content, 'Hello agent');
      expect(loaded.history.turns[1].role, 'assistant');
      expect(loaded.history.turns[1].content, 'Hello inspector');
    });

    test('persists observation text and photo references', () async {
      final external = await writeTempPhoto('source.jpg', 'photo-bytes');
      final storedPath = await storage.saveImage(external.path);

      final session = buildSession(
        id: 'roundtrip',
        inspectorId: 'Lee',
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            text: 'North stairwell blocked',
            photoFileRef: storedPath,
          ),
        ],
      );
      await storage.saveSession(session);
      final loaded = await storage.loadSession('roundtrip');

      expect(loaded, isNotNull);
      expect(loaded!.inspectorId, 'Lee');
      expect(loaded.observations.single.text, 'North stairwell blocked');
      expect(loaded.observations.single.photoFileRef, storedPath);
      expect(File(storedPath).existsSync(), isTrue);
    });

    test('migrates external photo paths into managed photos dir', () async {
      final external = await writeTempPhoto('camera.jpg', 'temp-bytes');
      final session = buildSession(
        id: 'migrate',
        observations: [
          Observation(
            id: 'obs-1',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            photoFileRef: external.path,
          ),
        ],
      );
      await storage.saveSession(session);
      final loaded = await storage.loadSession('migrate');

      final ref = loaded!.observations.single.photoFileRef!;
      expect(ref, isNot(external.path));
      expect(
        ref,
        contains('${Platform.pathSeparator}photos${Platform.pathSeparator}'),
      );
      expect(File(ref).existsSync(), isTrue);
    });

    test('stores photo refs as basenames on disk; resolves on load', () async {
      final external = await writeTempPhoto('source.jpg', 'photo-bytes');
      final storedPath = await storage.saveImage(external.path);

      await storage.saveSession(buildSession(
        id: 'relative',
        floorplanPath: storedPath,
        observations: [
          Observation(
            id: 'o',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            photoFileRef: storedPath,
          ),
        ],
      ));

      final raw = jsonDecode(await File(
        join(tempDir.path, 'sessions', 'relative', 'session.json'),
      ).readAsString()) as Map<String, dynamic>;
      expect(raw['floorplan_path'], isNot(contains(Platform.pathSeparator)));
      expect(
        (raw['observations'] as List).single['photo_file_ref'],
        isNot(contains(Platform.pathSeparator)),
      );

      final loaded = await storage.loadSession('relative');
      expect(loaded!.floorplanPath, storedPath);
      expect(loaded.observations.single.photoFileRef, storedPath);
    });
  });

  group('deleteSession', () {
    test('removes session dir, index entry, and referenced photos', () async {
      final external = await writeTempPhoto('p.jpg', 'bytes');
      final storedPath = await storage.saveImage(external.path);

      await storage.saveSession(buildSession(
        id: 'gone',
        floorplanPath: storedPath,
        observations: [
          Observation(
            id: 'o',
            timestamp: DateTime(2026, 5, 9, 9, 30),
            photoFileRef: storedPath,
          ),
        ],
      ));

      await storage.deleteSession('gone');
      expect(await storage.loadSession('gone'), isNull);
      expect(File(storedPath).existsSync(), isFalse);
      expect(
        Directory(join(tempDir.path, 'sessions', 'gone')).existsSync(),
        isFalse,
      );
      final index = jsonDecode(
        await File(join(tempDir.path, 'sessions', 'index.json'))
            .readAsString(),
      ) as List;
      expect(index, isEmpty);
    });
  });

  group('deleteAllSessions', () {
    test('empties the sessions directory and clears the index', () async {
      await storage.saveSession(buildSession(id: 'a'));
      await storage.saveSession(buildSession(id: 'b'));

      await storage.deleteAllSessions();
      expect(await storage.listSessions(), isEmpty);
      expect(
        Directory(join(tempDir.path, 'sessions')).listSync().whereType<Directory>(),
        isEmpty,
      );
    });
  });

  group('index.json', () {
    test('rebuilds from session files when missing', () async {
      await storage.saveSession(buildSession(id: 'a', name: 'A'));
      await storage.saveSession(buildSession(id: 'b', name: 'B'));

      final indexFile =
          File(join(tempDir.path, 'sessions', 'index.json'));
      await indexFile.delete();

      final fresh = LocalSessionStorage(tempDir.path);
      await fresh.ensureInitialized();
      final list = await fresh.listSessions();
      expect(list.map((m) => m.name).toSet(), {'A', 'B'});
      expect(indexFile.existsSync(), isTrue);
    });

    test('rebuilds when corrupted', () async {
      await storage.saveSession(buildSession(id: 'a', name: 'A'));

      final indexFile =
          File(join(tempDir.path, 'sessions', 'index.json'));
      await indexFile.writeAsString('not valid json {');

      final fresh = LocalSessionStorage(tempDir.path);
      await fresh.ensureInitialized();
      final list = await fresh.listSessions();
      expect(list.map((m) => m.name), ['A']);
    });

    test('written entries match saved session metadata', () async {
      await storage.saveSession(buildSession(
        id: 'm',
        zipCode: '10001',
        buildingType: 'hospital',
        status: 'open',
        inspectorId: 'Hart',
        riskLevel: 'high',
      ));

      final entries = jsonDecode(
        await File(join(tempDir.path, 'sessions', 'index.json'))
            .readAsString(),
      ) as List;
      expect(entries, hasLength(1));
      final entry = entries.single as Map<String, dynamic>;
      expect(entry['id'], 'm');
      expect(entry['zip_code'], '10001');
      expect(entry['building_type'], 'hospital');
      expect(entry['status'], 'open');
      expect(entry['inspector_id'], 'Hart');
      expect(entry['risk_level'], 'high');
    });
  });

  group('saveImage', () {
    test('throws when source file does not exist', () async {
      expect(
        () => storage.saveImage('/tmp/nope-${DateTime.now().microsecondsSinceEpoch}.jpg'),
        throwsException,
      );
    });

    test('copies the file into photos/ with a unique name', () async {
      final src = await writeTempPhoto('thing.png', 'data');
      final managed1 = await storage.saveImage(src.path);
      final managed2 = await storage.saveImage(src.path);
      expect(managed1, isNot(managed2));
      expect(File(managed1).readAsStringSync(), 'data');
      expect(File(managed2).readAsStringSync(), 'data');
    });
  });
}
