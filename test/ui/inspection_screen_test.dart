import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firesight/ui/inspection_screen.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/models/observation.dart';
import 'package:firesight/services/session/session_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionService extends Mock implements SessionService {}

class InspectionSessionFake extends Fake implements InspectionSession {}

void main() {
  late MockSessionService mockSessionService;

  setUpAll(() {
    registerFallbackValue(InspectionSessionFake());
  });

  setUp(() {
    mockSessionService = MockSessionService();
  });

  testWidgets('InspectionScreen has a save button in AppBar', (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Test Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockSessionService.createSession(any()))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.loadSession(any()))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(),
        ),
      ),
    );

    // Initial loading
    await tester.pump();
    // Wait for session to load
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byTooltip('Save Inspection'), findsOneWidget);
  });

  testWidgets('tapping save button calls saveSession and shows SnackBar',
      (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Test Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockSessionService.createSession(any()))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.save));
    await tester.pump(); // Start SnackBar animation

    verify(() => mockSessionService.saveSession(any())).called(1);
    expect(find.text('Inspection saved successfully'), findsOneWidget);
  });

  testWidgets(
      'renders saved observations and editable metadata for existing sessions',
      (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Warehouse A',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      inspectorId: 'Inspector Kim',
      observations: [
        Observation(
          id: 'obs-1',
          timestamp: DateTime.now(),
          text: 'Extinguisher cabinet blocked',
        ),
      ],
    );

    when(() => mockSessionService.loadSession('test-id'))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(sessionId: 'test-id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Saved Observations'), findsOneWidget);
    expect(find.text('Extinguisher cabinet blocked'), findsOneWidget);
    expect(find.text('Warehouse A'), findsWidgets);
    expect(find.text('Inspector Kim'), findsOneWidget);
  });

  testWidgets('save uses edited name and inspector', (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Original Name',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockSessionService.loadSession('test-id'))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(sessionId: 'test-id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Renamed Session');
    await tester.enterText(find.byType(TextField).at(1), 'Inspector Hart');
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    final savedSession =
        verify(() => mockSessionService.saveSession(captureAny()))
            .captured
            .single as InspectionSession;
    expect(savedSession.name, 'Renamed Session');
    expect(savedSession.inspectorId, 'Inspector Hart');
  });

  testWidgets('can add a note to a previously saved session', (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Existing Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockSessionService.loadSession('test-id'))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(sessionId: 'test-id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Note'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'Follow-up hazard note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final savedSession =
        verify(() => mockSessionService.saveSession(captureAny())).captured.last
            as InspectionSession;
    expect(savedSession.observations.single.text, 'Follow-up hazard note');
  });

  testWidgets('can edit a note from a previously saved session',
      (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Existing Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      observations: [
        Observation(
          id: 'obs-1',
          timestamp: DateTime.now(),
          text: 'Original note',
        ),
      ],
    );

    when(() => mockSessionService.loadSession('test-id'))
        .thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionServiceProvider.overrideWith((ref) => mockSessionService),
        ],
        child: const MaterialApp(
          home: InspectionScreen(sessionId: 'test-id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Original note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Note'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Updated note');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    final savedSession =
        verify(() => mockSessionService.saveSession(captureAny())).captured.last
            as InspectionSession;
    expect(savedSession.observations.single.text, 'Updated note');
  });
}
