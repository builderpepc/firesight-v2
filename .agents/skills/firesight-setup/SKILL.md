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
flutter --version        # Must be ≥ 3.0
adb --version            # Must be present (from Android SDK platform-tools)
node --version           # Required for Firebase CLI
dart pub global list     # Check for flutterfire_cli
```

If `flutterfire_cli` is not listed, install it:
```bash
dart pub global activate flutterfire_cli
```

If the Firebase CLI is not installed:
```bash
npm install -g firebase-tools
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

### Enable Gemini Developer API

This cannot be done from the CLI — tell the developer:

> In the Firebase Console for project `firesight-app`, navigate to **Build → AI Logic** and
> enable the Gemini Developer API. This is required for the online voice agent (Tier 1).

---

## Phase 3 — Cactus Native Library (Android)

Cactus provides on-device LLM inference. Its native `.so` must be placed manually.

### Download

Go to https://github.com/cactus-compute/cactus/releases and download the latest Android release
archive. Extract it.

### Place the library

```bash
# Create the directory if it doesn't exist
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Copy the library — adjust the source path to where you extracted the release
cp <extracted-path>/arm64-v8a/libcactus.so android/app/src/main/jniLibs/arm64-v8a/libcactus.so
```

### Verify

```bash
ls android/app/src/main/jniLibs/arm64-v8a/libcactus.so
```

Must exit 0. If the file is missing, the app will build but crash at runtime when attempting
on-device inference.

### iOS note

iOS setup requires Xcode on a macOS machine. See the stub in `docs/ios-setup-stub.md` (if it
exists) or the Cactus releases page for `Cactus.xcframework`. This is deferred to a macOS
contributor.

---

## Phase 4 — Model Files

Cactus loads GGUF model files from the device's local storage at runtime. The app looks in the
`models/` subdirectory of the app's documents directory (configured in `lib/core/constants.dart`).

Download from https://huggingface.co/Cactus-Compute and push to the connected device:

| Tier | Model to download | Use case |
|------|-------------------|----------|
| Tier 2 | Gemma 4 E2B or E4B (GGUF) | No internet, capable device (≥ 6 GB RAM). **Not viable on Samsung Galaxy S22** — skip for S22 testing. |
| Tier 3 | Gemma 3 1B (GGUF) | No internet, lower-power device |

To push a model file to a connected Android device:
```bash
# Find the app's files directory (requires a debug build)
adb shell run-as com.firesight.firesight mkdir -p files/models

adb push <local-model.gguf> /sdcard/Download/<model-file>.gguf
adb shell run-as com.firesight.firesight cp /sdcard/Download/<model-file>.gguf files/models/
```

Model files are large (1–8 GB). Skip this phase if only testing the online (Gemini) tier.

---

## Phase 5 — Android SDK

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

## Phase 6 — Meta Ray-Ban Glasses SDK

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

## Phase 7 — Android Emulator Setup (no physical device)

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

## Phase 8 — Build and Verify

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
| `Failed to find target 'android-36'` | Run `sdkmanager "platforms;android-36"` |
| `libcactus.so not found` at runtime | Place the file at `android/app/src/main/jniLibs/arm64-v8a/libcactus.so` |
| Gemini API calls fail | Enable the Gemini Developer API in Firebase Console → AI Logic |
| 42 packages have newer incompatible versions | Informational only — `flutter pub get` pins to compatible versions, no action needed |
