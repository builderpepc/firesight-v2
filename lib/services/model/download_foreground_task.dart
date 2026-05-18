import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry point for the foreground service isolate.
///
/// Must be a top-level function so it survives isolate spawning.
@pragma('vm:entry-point')
void downloadTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadTaskHandler());
}

/// Minimal task handler — the foreground service exists only to hold the
/// Android foreground service wakelock and wifi-lock so the Dio download
/// in the main isolate is not paused by Doze mode when the screen turns off.
class _DownloadTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Initialises [FlutterForegroundTask]. Call once from [main] after
/// [WidgetsFlutterBinding.ensureInitialized].
void initDownloadForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'model_download',
      channelName: 'Model Download',
      channelDescription: 'Keeps the model download running in the background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
      allowAutoRestart: false,
    ),
  );
}
