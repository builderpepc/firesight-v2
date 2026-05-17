import Flutter
import UIKit
import ZIPFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let kZipChannel = "com.firesight.firesight/zip"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FiresightZip") else { return }
    let messenger = registrar.messenger()
    let zipChannel = FlutterMethodChannel(name: kZipChannel, binaryMessenger: messenger)

    zipChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "extractZip":
        guard
          let args = call.arguments as? [String: Any],
          let zipPath = args["zipPath"] as? String,
          let destPath = args["destPath"] as? String
        else {
          result(FlutterError(code: "BAD_ARGS", message: "zipPath/destPath required", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            try self.extractZip(zipPath: zipPath, destPath: destPath)
            DispatchQueue.main.async { result(nil) }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "EXTRACT_FAILED", message: error.localizedDescription, details: nil))
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Streams each entry to disk via ZIPFoundation's default buffered extract.
  // RAM stays bounded regardless of archive size — mirrors the Android impl.
  private func extractZip(zipPath: String, destPath: String) throws {
    let fm = FileManager.default
    let destURL = URL(fileURLWithPath: destPath, isDirectory: true)
    try fm.createDirectory(at: destURL, withIntermediateDirectories: true)

    let archive = try Archive(url: URL(fileURLWithPath: zipPath), accessMode: .read)
    for entry in archive {
      let outURL = destURL.appendingPathComponent(entry.path)
      if entry.type == .directory {
        try fm.createDirectory(at: outURL, withIntermediateDirectories: true)
      } else {
        try fm.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = try archive.extract(entry, to: outURL)
      }
    }
  }
}
