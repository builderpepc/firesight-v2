/// Actions the voice agent requests the UI to execute on the active session.
sealed class VoiceAction {
  const VoiceAction();
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
