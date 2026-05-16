import 'dart:async';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Dev-mode placeholder voice agent. Used in [InspectionScreen] until the
/// production voice flow is wired to the real tier-based agents. Exposes
/// [simulateCommand] so the in-app voice contract can be exercised without
/// real audio input.
class MockVoiceAgent implements VoiceAgent {
  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _processingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  Future<void> Function()? _onUploadFloorplan;
  Future<void> Function(String notes)? _onMarkAsset;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<bool> get processingStream => _processingController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  void setToolHandlers({
    Future<void> Function()? onUploadFloorplan,
    Future<void> Function(String notes)? onMarkAsset,
  }) {
    _onUploadFloorplan = onUploadFloorplan;
    _onMarkAsset = onMarkAsset;
  }

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
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
    await _processingController.close();
    await _errorController.close();
  }
}
