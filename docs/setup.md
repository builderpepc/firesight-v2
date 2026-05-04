# FireSight — Developer Setup Guide

## Prerequisites

- Flutter SDK (≥ 3.0)
- Android Studio with Android SDK 36 installed
- Firebase CLI + FlutterFire CLI
- Node.js (for Firebase CLI)

---

## 1. Firebase Project Setup

### Install CLIs
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

### Authenticate and configure
```bash
firebase login
flutterfire configure --project=firesight-app
```

This generates `lib/firebase_options.dart` and places `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` automatically.

### Enable the Gemini API
In the [Firebase Console](https://console.firebase.google.com/project/firesight-app), navigate to **Build → AI Logic** and enable the Gemini Developer API. This is required for voice agent Tier 1 (online mode).

---

## 2. Cactus Native Library Setup

Cactus provides on-device LLM inference (voice agent Tiers 2 and 3). Its native `.so` / `.xcframework` must be placed manually before building.

### Android

1. Download the latest Cactus Android release from the [Cactus GitHub releases page](https://github.com/cactus-compute/cactus/releases).
2. Extract `libcactus.so` for the `arm64-v8a` ABI.
3. Place it at:
   ```
   android/app/src/main/jniLibs/arm64-v8a/libcactus.so
   ```
4. The `cactus` Flutter pub package will pick this up automatically at build time.

### iOS

> **TODO(ios):** Requires a macOS contributor with Xcode.

1. Download `Cactus.xcframework` from the [Cactus GitHub releases page](https://github.com/cactus-compute/cactus/releases).
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Drag `Cactus.xcframework` into the Runner target under **Frameworks, Libraries, and Embedded Content**.
4. Set the embed option to **Embed & Sign**.

---

## 3. Model Files

Cactus loads GGUF model files from the device's local storage. Download the appropriate Cactus-optimized models from [HuggingFace](https://huggingface.co/Cactus-Compute) and place them on the device:

| Tier | Model | Use case |
|------|-------|----------|
| Tier 2 | Gemma 4 E4B / E2B (GGUF) | No internet, capable device (≥ 6 GB RAM) — **not viable on Galaxy S22** |
| Tier 3 | Gemma 3 1B (GGUF) | No internet, lower-power device |

The app stores model files under the `models/` subdirectory of the app's documents directory. Path is configured in `lib/core/constants.dart`.

---

## 4. Meta Ray-Ban Glasses SDK Setup

> **Status:** `meta_wearables_dat` Android package is temporarily disabled due to a dependency conflict with `android_id`. Re-enable it in `pubspec.yaml` once the conflict is resolved.

### Android (when re-enabled)
Follow the [Meta Wearables Device Access Toolkit Android guide](https://github.com/facebook/meta-wearables-dat-android).

### iOS

> **TODO(ios):** Requires a macOS contributor.

Follow the [Meta Wearables Device Access Toolkit iOS guide](https://github.com/facebook/meta-wearables-dat-ios/discussions).

---

## 5. Android SDK Configuration

The project requires Android SDK 36 (fully installed) and a minimum SDK of 23. These are set explicitly in `android/app/build.gradle.kts`:

```kotlin
compileSdk = 36
minSdk = 23
targetSdk = 36
```

If you see `Failed to find target 'android-34'`, reinstall the platform via Android Studio SDK Manager or:
```bash
sdkmanager "platforms;android-34"
```

---

## 6. Running the App

```bash
flutter pub get
flutter run          # runs on connected device/emulator
flutter build apk --debug   # Android APK only
```

Connect a Samsung Galaxy S22 (or any Android device with Android 6+) via USB with Developer Mode enabled.
