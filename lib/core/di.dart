import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/camera/camera_provider.dart';
import '../services/camera/phone_camera_provider.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/forms/form_autofill_engine.dart';
import '../services/forms/form_autofill_service.dart';
import '../services/forms/rule_based_form_autofill_engine.dart';
import '../services/pdf/pdf_export_service.dart';
import '../services/session/session_service.dart';
import '../services/session/local_session_storage.dart';
import '../services/session/session_storage.dart';
import '../services/session/session_export.dart';
import '../services/tts/tts_service.dart';
import '../services/voice/voice_agent_service.dart';
import '../models/session_metadata.dart';

/// Base path for all app documents (async — resolved once at startup).
final appDocsDirProvider = FutureProvider<Directory>((ref) async {
  return getApplicationDocumentsDirectory();
});

/// Session storage (file-based per PROJECT.md: `sessions/<id>/session.json`
/// + `photos/` + `sessions/index.json`).
final sessionStorageProvider = FutureProvider<SessionStorage>((ref) async {
  final dir = await ref.watch(appDocsDirProvider.future);
  final storage = LocalSessionStorage(dir.path);
  await storage.ensureInitialized();
  return storage;
});

/// CRUD operations for inspection sessions.
final sessionServiceProvider = FutureProvider<SessionService>((ref) async {
  final storage = await ref.watch(sessionStorageProvider.future);
  return SessionService(storage);
});

/// List of all session metadata.
final sessionsProvider = FutureProvider<List<SessionMetadata>>((ref) async {
  final service = await ref.watch(sessionServiceProvider.future);
  return service.listSessions();
});

/// Session export service.
final sessionExportProvider = FutureProvider<SessionExport>((ref) async {
  final storage = await ref.watch(sessionStorageProvider.future);
  return SessionExport(storage);
});

/// Network connectivity (interface-level).
/// NOTE: connectivity_plus reports interface state, not true internet reachability.
/// A device may be "online" here yet have no actual internet (e.g. captive portal).
/// A reachability probe should be added before relying on this for tier selection.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

/// Live stream of internet availability derived from ConnectivityService.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isOnline;
});

/// On-device text-to-speech.
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService(FlutterTts());
});

/// Offline PDF generation and sharing.
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

/// Pluggable form autofill engine. MVP uses local rules; Cactus/Gemini can
/// implement the same interface later.
final formAutofillEngineProvider = Provider<FormAutofillEngine>((ref) {
  // TODO: Select Cactus or Gemini here once AI autofill is implemented.
  // The UI should continue depending only on FormAutofillService.
  return const RuleBasedFormAutofillEngine();
});

final formAutofillServiceProvider = Provider<FormAutofillService>((ref) {
  return FormAutofillService(ref.watch(formAutofillEngineProvider));
});

/// Active camera provider. Defaults to phone camera; Meta glasses provider
/// returns isAvailable=false until the SDK conflict is resolved.
final cameraProviderProvider = Provider<CameraProvider>((ref) {
  // CameraController is stateful — initialised during camera feature implementation.
  return PhoneCameraProvider(null);
});

/// Voice agent tier selector — holds all agent dependencies and picks the
/// appropriate tier based on connectivity and device capability.
final voiceAgentServiceProvider = Provider<VoiceAgentService>((ref) {
  return VoiceAgentService(
    connectivity: ref.watch(connectivityServiceProvider),
    stt: SpeechToText(),
    tts: FlutterTts(),
  );
});
