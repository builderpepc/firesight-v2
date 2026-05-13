import 'dart:async';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Dev-mode placeholder voice agent. Used as the active agent until real
/// tier selection (Gemini / Cactus / NativeFallback) is implemented in
/// [VoiceAgentService.currentAgent]. Exposes [simulateCommand] so the in-app
/// voice contract can be exercised without real audio input.
///
/// This is intentionally kept in `lib/` (not `test/`) because it is the
/// runtime voice agent the app currently relies on.
class MockVoiceAgent implements VoiceAgent {
  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();

  Future<void> Function()? _onUploadFloorplan;
  Future<void> Function(String notes)? _onMarkAsset;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  void setToolHandlers({
    Future<void> Function()? onUploadFloorplan,
    Future<void> Function(String notes)? onMarkAsset,
  }) {
    _onUploadFloorplan = onUploadFloorplan;
    _onMarkAsset = onMarkAsset;
  }

  @override
  Future<void> startListening(InspectionSession session) async {
    _responseController.add("Mock Voice Agent started. You can say 'upload floorplan' or 'mark asset'.");
  }

  @override
  Future<void> stopListening() async {
    _responseController.add("Mock Voice Agent stopped.");
  }

  /// Simulate a user command for testing.
  void simulateCommand(String command) {
    _transcriptController.add(command);
    if (command.contains("upload floorplan")) {
      _responseController.add("Opening floorplan uploader...");
      _onUploadFloorplan?.call();
    } else if (command.contains("mark asset")) {
      _responseController.add("Taking photo for asset...");
      _onMarkAsset?.call("Marked via voice command");
    } else {
      _responseController.add("I didn't understand that command.");
    }
  }

  @override
  Future<void> dispose() async {
    await _transcriptController.close();
    await _responseController.close();
  }
}
