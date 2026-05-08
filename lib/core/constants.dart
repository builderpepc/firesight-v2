// App-wide constants for FireSight.

/// Model names
class ModelNames {
  // Gemini Live API (Tier 1 — internet required)
  static const String geminiLive = 'gemini-live-2.5-flash-preview-native-audio-09-2025';

  // Cactus on-device models (Tiers 2 & 3)
  static const String gemma4 = 'gemma-4b-it';
  static const String gemma3 = 'gemma-3-1b-it';
}

/// File paths
class AppPaths {
  static const String sessions = 'sessions';
  static const String photos = 'photos';
}

/// Timeouts (milliseconds)
class Timeouts {
  static const int defaultTimeout = 30000;
  static const int voiceInit = 15000;
}
