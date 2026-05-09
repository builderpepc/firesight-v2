import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firesight/ui/inspection_screen.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/models/inspection_session.dart';
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

    when(() => mockSessionService.createSession(any())).thenAnswer((_) async => session);
    when(() => mockSessionService.loadSession(any())).thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any())).thenAnswer((_) async => {});

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

  testWidgets('tapping save button calls saveSession and shows SnackBar', (tester) async {
    final session = InspectionSession(
      id: 'test-id',
      name: 'Test Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => mockSessionService.createSession(any())).thenAnswer((_) async => session);
    when(() => mockSessionService.saveSession(any())).thenAnswer((_) async => {});

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
}
