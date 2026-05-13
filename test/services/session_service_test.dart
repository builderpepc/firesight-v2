import 'package:flutter_test/flutter_test.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_service.dart';
import 'package:firesight/services/session/session_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionStorage extends Mock implements SessionStorage {}

void main() {
  late MockSessionStorage mockStorage;

  setUp(() {
    mockStorage = MockSessionStorage();
  });

  test('listSessions sorts by inspector then updated time', () async {
    final sessions = [
      SessionMetadata(
        id: '3',
        name: 'Gamma',
        createdAt: DateTime(2026, 5, 6),
        updatedAt: DateTime(2026, 5, 9, 8),
        inspectorId: 'Zulu',
      ),
      SessionMetadata(
        id: '1',
        name: 'Alpha',
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 9, 10),
        inspectorId: 'Bravo',
      ),
      SessionMetadata(
        id: '2',
        name: 'Beta',
        createdAt: DateTime(2026, 5, 7),
        updatedAt: DateTime(2026, 5, 9, 9),
        inspectorId: 'Bravo',
      ),
    ];

    when(() => mockStorage.listSessions()).thenAnswer((_) async => sessions);

    final service = SessionService(mockStorage);
    final sorted = await service.listSessions(
      sort: SessionSortOption.inspectorAsc,
    );

    expect(sorted.map((session) => session.id), ['1', '2', '3']);
  });
}
