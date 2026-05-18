import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifierProvider;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/audio/audio_output_service.dart';
import '../services/camera/camera_provider.dart';
import '../services/camera/phone_camera_provider.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/device/device_capability_service.dart';
import '../services/forms/form_autofill_engine.dart';
import '../services/forms/form_autofill_service.dart';
import '../services/forms/rule_based_form_autofill_engine.dart';
import '../services/pdf/pdf_export_service.dart';
import '../services/session/session_service.dart';
import '../services/session/local_session_storage.dart';
import '../services/session/session_storage.dart';
import '../services/session/session_export.dart';
import '../services/tts/tts_service.dart';
import '../services/model/model_download_service.dart';
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

/// Shared SpeechToText instance (used by Tier 2/3 agents and debug screen).
final sttProvider = Provider<SpeechToText>((ref) => SpeechToText());

/// Shared FlutterTts instance (used by Tier 2/3 agents and debug screen).
final ttsProvider = Provider<FlutterTts>((ref) => FlutterTts());

/// Firebase AI instance for Tier 1 (Gemini Live API).
final firebaseAIProvider = Provider<FirebaseAI>((ref) => FirebaseAI.vertexAI());

/// On-device text-to-speech (used for Tier 2/3 fallback agents).
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService(FlutterTts());
});

/// Real-time PCM audio output via SoLoud (used by GeminiVoiceAgent for Tier 1).
final audioOutputServiceProvider = Provider<AudioOutputService>((ref) {
  return AudioOutputService();
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

/// Device hardware capability queries (RAM detection for tier selection).
final deviceCapabilityProvider = Provider<DeviceCapabilityService>((ref) {
  return const DeviceCapabilityService();
});

/// Manages automatic download of the Gemma 4 E2B on-device model.
///
/// Watches [appDocsDirProvider]; auto-resolves once the docs directory is known.
final modelDownloadProvider =
    StateNotifierProvider<ModelDownloadNotifier, ModelDownloadStatus>((ref) {
  // appDocsDirProvider is async; return an idle notifier while it resolves,
  // then rebuild once the dir is available.
  final dirAsync = ref.watch(appDocsDirProvider);
  return dirAsync.when(
    data: (dir) => ModelDownloadNotifier(dir),
    loading: () => ModelDownloadNotifier(Directory('')),
    error: (_, __) => ModelDownloadNotifier(Directory('')),
  );
});

/// Voice agent tier selector — holds all agent dependencies and picks the
/// appropriate tier based on connectivity and device capability.
final voiceAgentServiceProvider = Provider<VoiceAgentService>((ref) {
  return VoiceAgentService(
    connectivity: ref.watch(connectivityServiceProvider),
    stt: ref.watch(sttProvider),
    tts: ref.watch(ttsProvider),
    firebaseAI: ref.watch(firebaseAIProvider),
    audioOutput: ref.watch(audioOutputServiceProvider),
    deviceCapability: ref.watch(deviceCapabilityProvider),
  );
});
