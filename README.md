# FireSight

Voice automation for fire department pre-incident inspections.

FireSight is a Flutter app for capturing inspection observations by voice, attaching photos, saving
inspection sessions locally, and exporting reports. The app is designed for mobile use with online
Gemini support and offline fallbacks.

## Setup

Use the detailed setup workflow in `.agents/skills/firesight-setup/SKILL.md` when preparing a new
machine. The project currently has verified iOS simulator setup on macOS and Android setup notes.

### Common prerequisites

```bash
flutter --version
node --version
dart pub global list
```

If `flutter` is installed by the VS Code Flutter extension but is not on `PATH`, either add the
SDK's `bin` directory to `PATH` or run commands with that SDK's absolute `bin/flutter` path.

Install Firebase tooling if needed:

```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
```

Fetch Flutter dependencies:

```bash
flutter pub get
```

## iOS

iOS setup has been verified on macOS with Xcode, CocoaPods, Flutter 3.41.9, and an iOS 26.4
simulator. The iOS deployment target is `15.0` because current FlutterFire pods require it.

Install CocoaPods if needed:

```bash
brew install cocoapods
```

Prepare iOS dependencies:

```bash
flutter precache --ios
flutter pub get
cd ios
pod install
cd ..
```

Build and run:

```bash
flutter analyze
flutter test
flutter build ios --no-codesign
flutter run -d <simulator-udid>
```

To list and boot simulators:

```bash
xcrun simctl list devices available
xcrun simctl boot <simulator-udid>
open -a Simulator
```

## Android

Android setup remains supported. Install Android SDK 36 and use the Android instructions in the
setup skill for SDK, emulator, and Cactus native library setup:

```bash
sdkmanager "platforms;android-36"
flutter build apk --debug
flutter run
```

On-device Cactus inference requires the Android native `libcactus.so` at:

```text
android/app/src/main/jniLibs/arm64-v8a/libcactus.so
```

## Firebase

Firebase configuration files must exist before platform builds:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Regenerate them when needed:

```bash
flutterfire configure --project=firesight-app
```

The online voice agent also requires the Gemini Developer API to be enabled in Firebase Console
under **Build -> AI Logic** for project `firesight-app`.
