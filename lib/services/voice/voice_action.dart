/// Actions the voice agent requests the UI to execute on the active session.
sealed class VoiceAction {
  const VoiceAction();
}

/// Agent requested to start a brand new inspection session.
class StartNewInspection extends VoiceAction {
  const StartNewInspection();
}

/// Agent requested to save the current session.
class SaveSession extends VoiceAction {
  const SaveSession();
}

/// Agent dictated a text observation the inspector said aloud.
class RecordObservation extends VoiceAction {
  const RecordObservation(this.text);
  final String text;
}

/// Agent wants a photo taken, optionally with a description label.
class TakePhoto extends VoiceAction {
  const TakePhoto({this.description});
  final String? description;
}

/// Agent wants the inspector to upload/replace the building floorplan.
class UploadFloorplan extends VoiceAction {
  const UploadFloorplan();
}
