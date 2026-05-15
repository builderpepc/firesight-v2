---
name: firesight-setup
description: >
  Complete environment setup for the FireSight Flutter project. Use this skill whenever a developer
  asks to set up FireSight, get the project running, configure dependencies, install the Cactus
  library, set up Firebase, or troubleshoot build failures related to missing setup steps. Also
  trigger this skill when the developer reports errors like "google-services.json not found",
  "libcactus.so missing", "SDK 36 not found", or asks why the app won't build from a fresh clone.
---

# FireSight Environment Setup

This skill sets up everything needed to build and run FireSight on a fresh development machine.
Work through each phase in order; each phase has a verification step — stop and fix before
continuing if a phase fails.

## Phase 0 — Link Agent Skills into Claude Code

`.claude/skills/` is gitignored and must be created as a directory junction (Windows) or symlink
(macOS/Linux) pointing to `.agents/skills/` so Claude Code auto-discovers project skills.

**Windows (PowerShell, run from project root):**
```powershell
# Only needed if .claude/skills doesn't already exist
if (-not (Test-Path .claude/skills)) {
    cmd /c mklink /J .claude\skills .agents\skills
}
```

**macOS / Linux:**
```bash
[ -e .claude/skills ] || ln -s ../.agents/skills .claude/skills
```

Verify:
```bash
ls .claude/skills/   # should list firesight-setup
```

---

## Prerequisites Check

Run these first to confirm the required tooling is installed:

```bash
flutter --version        # Must be ≥ 3.1.0
adb --version            # Must be present for Android work (from Android SDK platform-tools)
node --version           # Required for Firebase CLI
dart pub global list     # Check for flutterfire_cli
```

For iOS work on macOS, also verify:

```bash
xcodebuild -version      # Xcode must be installed
pod --version            # CocoaPods must be installed
xcrun simctl list devices available
```

If Flutter was installed by the VS Code Flutter extension but is not on `PATH`, use the SDK's
absolute `bin/flutter` path for setup commands, or add that `bin` directory to the shell `PATH`.

If `flutterfire_cli` is not listed, install it:
```bash
dart pub global activate flutterfire_cli
```

If the Firebase CLI is not installed:
```bash
npm install -g firebase-tools
```

If CocoaPods is not installed on macOS:
```bash
brew install cocoapods
```

---

## Phase 1 — Flutter Dependencies

```bash
flutter pub get
```

Then run a quick analysis to catch any obvious issues before investing time in the heavier setup steps:

```bash
flutter analyze
```

Fix any errors before proceeding. Warnings are acceptable.

---

## Phase 2 — Firebase Configuration

FireSight uses Firebase AI Logic (Gemini) for the online voice agent tier.

### Authenticate

```bash
firebase login
```

If already authenticated, this exits immediately. If it opens a browser, complete the OAuth flow.

### Generate platform config files

```bash
flutterfire configure --project=firesight-app
```

This command writes three files that must exist before the app will compile:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

If any of these already exist and look correct (non-empty, contain the project ID `firesight-app`),
you can skip `flutterfire configure` for that platform.

### Enable Vertex AI backend (required for Live API)

FireSight uses `FirebaseAI.vertexAI()` (not the Gemini Developer API) because the Live API
(streaming bidirectional audio) is only available on the Vertex AI backend.

This requires two steps that cannot be done from the CLI:

**Step 1 — Enable GCP APIs.** In the [Google Cloud Console](https://console.cloud.google.com)
for the `firesight-app` project, navigate to **APIs & Services → Enable APIs** and enable:
- `Firebase AI Logic API` (`firebasevertexai.googleapis.com`)
- `Vertex AI API` (`aiplatform.googleapis.com`)

**Step 2 — Enable billing.** Vertex AI requires a billing account linked to the GCP project.
In the Cloud Console, go to **Billing** and link a billing account if one is not already attached.
Without billing, API calls will fail at runtime with a WebSocket 1008 error.

---

## Phase 3 — iOS Setup

iOS setup has been verified on macOS with Xcode, CocoaPods, Flutter 3.41.9, and an iOS 26.4
simulator. Keep the iOS deployment target at **15.0** because the current FlutterFire pods
(`firebase_core`, `firebase_auth`, and `firebase_ai`) require iOS 15 or newer.

### Required checked-in scaffold

These files must exist and should be committed:

- `ios/Podfile`
- `ios/Podfile.lock`
- `ios/Flutter/Debug.xcconfig`
- `ios/Flutter/Release.xcconfig`
- `ios/Flutter/Profile.xcconfig`
- `ios/Runner/GoogleService-Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner.xcworkspace/contents.xcworkspacedata`

Do not commit generated local artifacts such as `ios/Pods/`, `ios/.symlinks/`,
`ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`, or `build/`.

### Install iOS dependencies

```bash
flutter precache --ios
flutter pub get
cd ios
pod install
cd ..
```

If `pod install` fails with a missing Flutter engine artifact such as
`Flutter.xcframework must exist`, run:

```bash
flutter precache --ios
```

If `pod install` says Firebase pods require a higher minimum deployment target, confirm the
project and `ios/Podfile` are still set to `15.0`.

### Build and run on an iOS simulator

List simulators:

```bash
xcrun simctl list devices available
```

Boot one simulator, for example:

```bash
xcrun simctl boot <simulator-udid>
open -a Simulator
```

Run the app:

```bash
flutter run -d <simulator-udid>
```

The first run should build, install, and launch FireSight in Simulator. If Flutter reports
`Target native_assets required define SdkRoot but it was not provided` while still launching
successfully, treat it as a warning unless the app fails to install or run.

To relaunch an already-installed simulator app without attaching Flutter:

```bash
xcrun simctl launch <simulator-udid> com.firesight.firesight
```

### iOS smoke test

After launch, verify:

1. The HomeScreen renders.
2. Tapping the FAB opens a new inspection.
3. No crash or red error screen appears.

The Meta Ray-Ban glasses SDK still requires physical device testing for camera capture. The
simulator is sufficient for validating the Flutter app scaffold and normal navigation.

---

## Phase 4 — Cactus Native Library (Android)

Cactus provides on-device LLM inference. `libcactus.so` (arm64-v8a) is **already committed** to
the repo at `android/app/src/main/jniLibs/arm64-v8a/libcactus.so` and is included automatically
in every APK build. No manual download is needed for normal development.

### Verify (fresh clone)

```bash
ls android/app/src/main/jniLibs/arm64-v8a/libcactus.so
```

Must exit 0. If the file is somehow missing (e.g., from a partial clone), see the rebuild
instructions below.

### Rebuilding `libcactus.so` from source

Cactus only supports `arm64-v8a` due to ARM NEON requirements — x86_64 builds are explicitly
blocked. You need a Linux environment (WSL on Windows or native Linux/macOS) with Android NDK r27c.

**On Windows via WSL:**

```bash
# One-time: download NDK r27c into WSL
wsl -d Ubuntu bash << 'WSLEOF'
mkdir -p ~/android-ndk
cd ~/android-ndk
curl -O https://dl.google.com/android/repository/android-ndk-r27-linux.zip
unzip android-ndk-r27-linux.zip
WSLEOF
```

```bash
# Clone Cactus and build
wsl -d Ubuntu bash << 'WSLEOF'
git clone https://github.com/cactus-compute/cactus ~/cactus-build/cactus
cd ~/cactus-build/cactus/android
NDK=~/android-ndk/android-ndk-r27
cmake -S . -B build-arm64 \
  -DCMAKE_TOOLCHAIN_FILE=$NDK/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DPLATFORM_CPU_ONLY=1 \
  -GNinja
cmake --build build-arm64 --target cactus -j$(nproc)
cp build-arm64/libcactus.so libcactus-arm64-v8a.so
WSLEOF
```

Then copy the built `.so` into the project:

```bash
wsl -d Ubuntu bash << 'WSLEOF'
cp ~/cactus-build/cactus/android/libcactus-arm64-v8a.so \
   /mnt/c/path/to/firesight-v2/android/app/src/main/jniLibs/arm64-v8a/libcactus.so
WSLEOF
```

**On macOS / Linux:** same steps without the `wsl` wrapper.

### iOS note

`cactus-ios.xcframework` has not yet been integrated. iOS Cactus inference is deferred to a
macOS contributor. The iOS app scaffold builds and runs in Simulator through CocoaPods without it.

---

## Phase 5 — Model Files

Cactus loads GGUF model files from the device's local storage at runtime. The app looks in the
`cactus/` subdirectory of the app's documents directory (`getApplicationDocumentsDirectory()`).
On Android this resolves to `/data/user/0/com.firesight.firesight/app_flutter/cactus/`.

Download from https://huggingface.co/Cactus-Compute and push to the connected device:

| Tier | Model slug | Use case |
|------|-----------|----------|
| Tier 2 E2B | `gemma-4-e2b-it-int4.gguf` | No internet, capable device (≥ 4 GB RAM). ~4.4 GB. |
| Tier 2 E4B | `gemma-4-e4b-it-int8.gguf` | No internet, high-RAM device (≥ 8 GB). ~8 GB. |
| Tier 3 | Gemma 3 1B (GGUF) | No internet, lower-power device |

To push a model file to a connected Android device:
```bash
# Create the cactus subdir and push
adb shell run-as com.firesight.firesight mkdir -p app_flutter/cactus

adb push <local-model.gguf> /sdcard/Download/<model-file>.gguf
adb shell run-as com.firesight.firesight cp /sdcard/Download/<model-file>.gguf app_flutter/cactus/
```

If `startListening()` is invoked and the model file is absent, the Voice Agent Debug screen will
display a red error banner with the exact expected path — use that path with `adb push`.

Model files are large (1–8 GB). Skip this phase if only testing the online (Gemini) tier.

---

## Phase 6 — Android SDK

The project requires **Android SDK 36**. `minSdk` is managed by the Flutter Gradle plugin
(`flutter.minSdkVersion`, currently 24 in Flutter 3.41+) — do not hardcode it.

### Verify SDK 36 is installed

```bash
sdkmanager --list_installed | grep "platforms;android-36"
```

If not present:
```bash
sdkmanager "platforms;android-36"
```

Check `android/app/build.gradle.kts` — confirm these values:
```kotlin
compileSdk = 36
minSdk = flutter.minSdkVersion
targetSdk = 36
```

---

## Phase 7 — Meta Ray-Ban Glasses SDK

> **Status: package included, implementation pending.** `meta_wearables_dat ^0.1.3` is in
> `pubspec.yaml` (the prior `android_id` conflict was resolved in v0.1.3). `MetaGlassesCameraProvider`
> is stubbed (`isAvailable` always returns `false`) until the capture logic is implemented.
>
> To implement: follow the [Meta Wearables Device Access Toolkit Android guide](https://github.com/facebook/meta-wearables-dat-android)
> and wire up `MetaGlassesProvider.capturePhoto()`.

The Meta Wearables native Android libraries are hosted on GitHub Packages and require a GitHub
personal access token with `read:packages` scope to download during a Gradle build.

### Add GitHub token to local.properties

Add the following line to `android/local.properties` (this file is gitignored):

```
github_token=<your_github_pat>
```

Create a token at GitHub → Settings → Developer settings → Personal access tokens → Fine-grained
tokens (or classic tokens) — only `read:packages` scope is required.

Alternatively, set the `GITHUB_TOKEN` environment variable instead of using `local.properties`.

Without this token, `flutter build apk` will fail with:

```
Could not find com.meta.wearable:mwdat-core:0.3.0
```

The SDK itself requires a physical Android or iOS device — it cannot be tested in an emulator.

---

## Phase 8 — Android Emulator Setup (no physical device)

If the developer does not have an Android device, set up an emulator. Note that the Meta
Ray-Ban glasses SDK cannot be tested in an emulator — physical Android or iOS devices are
needed for that.

### Install the system image

```bash
sdkmanager "system-images;android-35;google_apis_playstore;x86_64"
```

This is ~1.5 GB and takes a few minutes.

### Create the AVD

```bash
echo no | avdmanager create avd \
  --name "firesight_dev" \
  --package "system-images;android-35;google_apis_playstore;x86_64" \
  --device "pixel_6"
```

Verify: `avdmanager list avd` should show `firesight_dev`.

### Boot the emulator

**macOS / Linux:**
```bash
$ANDROID_HOME/emulator/emulator -avd firesight_dev -no-snapshot-load &
```

**Windows (PowerShell):**
```powershell
Start-Process "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" "-avd firesight_dev -no-snapshot-load"
```

Wait for the emulator to fully boot (the home screen appears) before running the app. You can
poll boot completion with:
```bash
adb -s emulator-5554 shell getprop sys.boot_completed   # prints "1" when ready
```

The first cold boot takes 2–5 minutes. Subsequent boots are faster if you allow snapshots
(omit `-no-snapshot-load`).

---

## Phase 9 — Build and Verify

### Analyze and test

```bash
flutter analyze
flutter test
```

### Build iOS without codesigning

```bash
flutter build ios --no-codesign
```

A successful iOS build prints a path ending in `build/ios/iphoneos/Runner.app`.

### Build a debug APK

```bash
flutter build apk --debug
```

A successful build prints a path ending in `app-debug.apk`. CMake 3.22.1 will be downloaded
automatically on the first build if not present — this is expected and takes a few minutes.

If you previously built for a different device architecture (e.g. physical phone → emulator),
run `flutter clean` first to avoid stale APK errors.

### Run on device

```bash
flutter run   # auto-selects the only connected device/emulator
```

For a physical Android device: enable **Developer Options → USB Debugging** before connecting.

### Smoke test

After launch, verify:
1. The HomeScreen renders (FireSight title, "Recent Sessions - TODO" placeholder, FAB)
2. Tapping the FAB navigates to the InspectionScreen ("New Inspection" title)
3. No crash or red error screen
4. Tap the bug icon (🐛) in the AppBar to open the **Voice Agent Debug** screen; with internet,
   the tier badge should read "Tier 1 — Gemini" and the Start button should be enabled

To find the FAB's tap coordinates on any device without guessing:
```bash
adb shell uiautomator dump /sdcard/ui.xml
adb pull /sdcard/ui.xml
# grep for "New Inspection" and read the bounds attribute
```

Then tap the center of those bounds:
```bash
adb shell input tap <cx> <cy>
```

---

## Common Errors

| Error | Fix |
|-------|-----|
| `google-services.json not found` | Run `flutterfire configure --project=firesight-app` |
| `GoogleService-Info.plist not found` | Run `flutterfire configure --project=firesight-app` or restore `ios/Runner/GoogleService-Info.plist` |
| Firebase pod requires a higher minimum deployment target | Keep iOS deployment target and `ios/Podfile` at `15.0` |
| `Flutter.xcframework must exist` during `pod install` | Run `flutter precache --ios`, then rerun `pod install` |
| CocoaPods warns it did not set base configuration | Include Pods xcconfigs from `ios/Flutter/Debug.xcconfig`, `Release.xcconfig`, and `Profile.xcconfig` |
| CoreSimulatorService connection errors | Rerun `xcrun simctl ...` with normal macOS permissions; restart Simulator if needed |
| `Failed to find target 'android-36'` | Run `sdkmanager "platforms;android-36"` |
| `libcactus.so not found` at runtime | The file should already be committed at `android/app/src/main/jniLibs/arm64-v8a/libcactus.so` — check git status; if missing, rebuild from source (see Phase 4) |
| Gemini API calls fail with WebSocket 1008 "not found" | Wrong model name — use `gemini-live-2.5-flash-preview-native-audio-09-2025` (check `lib/core/constants.dart`) |
| Gemini API calls fail with WebSocket 1008 "API not enabled" | Enable `firebasevertexai.googleapis.com` and `aiplatform.googleapis.com` in GCP Console |
| Gemini API calls fail with WebSocket 1008 "billing must be enabled" | Link a billing account to the GCP project in Cloud Console → Billing |
| Voice agent connects but agent replies never appear | Do not use `ResponseModalities.text` with the native-audio model — use `ResponseModalities.audio` with `outputAudioTranscription: AudioTranscriptionConfig()` |
| Android emulator mic sends silence / no transcript | Run `adb emu avd hostmicon` to enable host-mic passthrough; the emulator virtual mic sends silence by default |
| 42 packages have newer incompatible versions | Informational only — `flutter pub get` pins to compatible versions, no action needed |
