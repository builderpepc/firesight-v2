import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firesight/ui/home_screen.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/session_metadata.dart';
import 'package:firesight/services/session/session_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

class MockGoRouter extends Mock implements GoRouter {}
class MockSessionService extends Mock implements SessionService {}

void main() {
  late MockSessionService mockSessionService;

  setUp(() {
    mockSessionService = MockSessionService();
  });

  group('HomeScreen', () {
    testWidgets('renders list of sessions', (tester) async {
      final now = DateTime.now();
      final sessions = [
        SessionMetadata(
          id: '1',
          name: 'Session 1',
          createdAt: now,
          updatedAt: now,
        ),
        SessionMetadata(
          id: '2',
          name: 'Session 2',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsProvider.overrideWith((ref) => sessions),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('shows confirmation dialog and calls deleteSession when confirmed', (tester) async {
      final now = DateTime.now();
      final session = SessionMetadata(
        id: '1',
        name: 'Session 1',
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockSessionService.deleteSession('1')).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsProvider.overrideWith((ref) => [session]),
            sessionServiceProvider.overrideWith((ref) => mockSessionService),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Inspection'), findsOneWidget);
      expect(find.text('Are you sure you want to delete "Session 1"?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockSessionService.deleteSession('1')).called(1);
    });

    testWidgets('shows confirmation dialog and calls deleteAllSessions when confirmed', (tester) async {
      when(() => mockSessionService.deleteAllSessions()).thenAnswer((_) async => {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsProvider.overrideWith((ref) => []),
            sessionServiceProvider.overrideWith((ref) => mockSessionService),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      expect(find.text('Delete All Inspections'), findsOneWidget);

      await tester.tap(find.text('Delete All'));
      await tester.pumpAndSettle();

      verify(() => mockSessionService.deleteAllSessions()).called(1);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('No recent sessions'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionsProvider.overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('New Inspection'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
