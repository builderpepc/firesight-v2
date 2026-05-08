import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firesight/core/di.dart';
import 'package:firesight/core/theme.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/connectivity/connectivity_service.dart';
import 'package:firesight/services/tts/tts_service.dart';
import 'package:firesight/services/voice/voice_agent.dart';
import 'package:firesight/services/voice/voice_agent_service.dart';
import 'package:firesight/ui/debug/debug_voice_screen.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}
class MockVoiceAgentService extends Mock implements VoiceAgentService {}
class MockTtsService extends Mock implements TtsService {}
class MockVoiceAgent extends Mock implements VoiceAgent {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      InspectionSession(
        id: 'fallback',
        name: 'Fallback',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  late MockConnectivityService connectivity;
  late MockVoiceAgentService agentService;
  late MockTtsService ttsService;

  setUp(() {
    connectivity = MockConnectivityService();
    agentService = MockVoiceAgentService();
    ttsService = MockTtsService();

    // Default: offline so most tests don't need a real agent.
    when(() => connectivity.isOnline)
        .thenAnswer((_) => Stream.value(false));
    when(() => connectivity.checkOnline()).thenAnswer((_) async => false);
    when(() => ttsService.speak(any())).thenAnswer((_) async {});
  });

  Widget buildSubject() => ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWithValue(connectivity),
          voiceAgentServiceProvider.overrideWithValue(agentService),
          ttsServiceProvider.overrideWithValue(ttsService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DebugVoiceScreen(),
        ),
      );

  testWidgets('shows correct title', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Voice Agent Debug'), findsOneWidget);
  });

  testWidgets('shows offline chip when not connected', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('shows online chip when connected', (tester) async {
    when(() => connectivity.isOnline).thenAnswer((_) => Stream.value(true));
    when(() => connectivity.checkOnline()).thenAnswer((_) async => true);

    await tester.pumpWidget(buildSubject());
    await tester.pump();

    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('start button is disabled when offline', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows error banner when resolveAgent throws offline', (tester) async {
    when(() => connectivity.isOnline).thenAnswer((_) => Stream.value(true));
    when(() => connectivity.checkOnline()).thenAnswer((_) async => true);
    when(() => agentService.resolveAgent()).thenThrow(
      UnimplementedError('Offline voice agents (Tiers 2 & 3) are not yet implemented.'),
    );

    await tester.pumpWidget(buildSubject());
    await tester.pump(); // connectivity update
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // async resolveAgent throws

    expect(find.textContaining('Tiers 2 & 3'), findsOneWidget);
  });

  testWidgets('transcript and response panels show placeholder when empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.text('Transcript'), findsOneWidget);
    expect(find.text('Responses'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('appends transcript entries from agent stream', (tester) async {
    final transcriptCtrl = StreamController<String>.broadcast();
    final responseCtrl = StreamController<String>.broadcast();
    final agent = MockVoiceAgent();

    when(() => connectivity.isOnline).thenAnswer((_) => Stream.value(true));
    when(() => connectivity.checkOnline()).thenAnswer((_) async => true);
    when(() => agentService.resolveAgent()).thenAnswer((_) async => agent);
    when(() => agent.startListening(any())).thenAnswer((_) async {});
    when(() => agent.transcriptStream).thenAnswer((_) => transcriptCtrl.stream);
    when(() => agent.responseStream).thenAnswer((_) => responseCtrl.stream);
    when(() => agent.stopListening()).thenAnswer((_) async {});
    when(() => agent.dispose()).thenAnswer((_) async {});

    await tester.pumpWidget(buildSubject());
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    transcriptCtrl.add('Exit door blocked');
    await tester.pump();

    expect(find.textContaining('Exit door blocked'), findsOneWidget);

    await transcriptCtrl.close();
    await responseCtrl.close();
  });
}
