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
  final _audioLevelController = StreamController<double>.broadcast();
  Timer? _audioTimer;

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
  Stream<double> get audioLevelStream => _audioLevelController.stream;

  @override
  Future<void> startListening(InspectionSession session, ConversationHistory history) async {
    _responseController.add("Mock Voice Agent started. Say 'new inspection', 'save session', 'upload floorplan', 'mark asset', or 'take photo'.");
    _startMockAudio();
  }

  @override
  Future<void> stopListening() async {
    _responseController.add("Mock Voice Agent stopped.");
    _audioTimer?.cancel();
    _audioLevelController.add(0.0);
  }

  void _startMockAudio() {
    _audioTimer?.cancel();
    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // Emit random amplitude between 0.1 and 0.8
      _audioLevelController.add(0.1 + (0.7 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000));
    });
  }

  /// Simulate a user command for testing.
  void simulateCommand(String command) {
    _transcriptController.add(command);
    if (command.contains('new inspection')) {
      _responseController.add("Starting new inspection…");
      _actionController.add(const StartNewInspection());
    } else if (command.contains('save session')) {
      _responseController.add("Saving current session…");
      _actionController.add(const SaveSession());
    } else if (command.contains('upload floorplan')) {
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
    _audioTimer?.cancel();
    await _transcriptController.close();
    await _responseController.close();
    await _processingController.close();
    await _errorController.close();
    await _actionController.close();
    await _audioLevelController.close();
  }
}
