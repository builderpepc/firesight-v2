# Install dependencies
flutter pub upgrade --major-versions

# How to Run

You can now launch the app by running this command in your terminal:

   1 flutter run -d 45443DF1-3579-4CFF-8181-F8803484138E

  If you want to use a different simulator, follow these steps:

   1. List available simulators:

   1     xcrun simctl list devices available
   2. Boot your preferred simulator:

   1     xcrun simctl boot <UDID>
   2     open -a Simulator
   3. Run the app:

   1     flutter run -d <UDID>

  Note: The Meta Ray-Ban glasses integration requires a physical iOS device for camera testing, but the simulator is perfect for testing the UI and core inspection workflows.
