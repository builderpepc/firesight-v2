import 'dart:async';
import 'package:firesight/models/conversation_history.dart';
import 'package:firesight/models/inspection_session.dart';
import 'package:firesight/services/voice/voice_action.dart';
import 'package:firesight/services/voice/voice_agent.dart';

/// Dev-mode placeholder voice agent. Used in [InspectionScreen] to exercise
/// the voice contract without real audio input. Call [simulateCommand] to
/// emit transcripts and actions as if the user spoke them.
class MockVoiceAgent implements VoiceAgent {
  final _transcriptController = StreamController<String>.broadcast();
  final _responseController = StreamController<String>.broadcast();
  final _processingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<Object>.broadcast();
  final _actionController = StreamController<VoiceAction>.broadcast();

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Stream<bool> get processingStream => _processingController.stream;

  @override
  Stream<Object> get errorStream => _errorController.stream;

  @override
  Stream<VoiceAction> get actionStream => _actionController.stream;

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
    _responseController.add("Mock Voice Agent started. Say 'upload floorplan', 'mark asset', or 'take photo'.");
  }

  @override
  Future<void> stopListening() async {
    _responseController.add("Mock Voice Agent stopped.");
  }

  /// Simulate a user command for testing.
  void simulateCommand(String command) {
    _transcriptController.add(command);
    if (command.contains('upload floorplan')) {
      _responseController.add("Requesting floorplan upload…");
      _actionController.add(const UploadFloorplan());
    } else if (command.contains('take photo')) {
      _responseController.add("Requesting photo capture…");
      _actionController.add(const TakePhoto(description: 'Demo photo'));
    } else if (command.contains('mark asset') || command.contains('mark')) {
      _responseController.add("Recording observation…");
      _actionController.add(const RecordObservation('Asset marked via voice command'));
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
    await _actionController.close();
  }
}
