import 'package:go_router/go_router.dart';
import 'package:firesight/ui/home_screen.dart';
import 'package:firesight/ui/inspection_screen.dart';
import 'package:firesight/ui/debug/debug_voice_screen.dart';

/// App router configuration.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/session/new',
      name: 'session-new',
      builder: (context, state) => const InspectionScreen(),
    ),
    GoRoute(
      path: '/session/:id',
      name: 'session',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return InspectionScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/debug/voice',
      name: 'debug-voice',
      builder: (context, state) => const DebugVoiceScreen(),
    ),
  ],
);
