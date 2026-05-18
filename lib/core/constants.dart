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

/// HuggingFace model download URLs.
///
/// ZIP archives contain individual Cactus `.weights` files (not a single GGUF).
/// [ModelDownloadService] extracts the full archive into a weights directory.
class ModelUrls {
  static const String gemma4E2bZip =
      'https://huggingface.co/Cactus-Compute/gemma-4-E2B-it/resolve/main/weights/gemma-4-e2b-it-int4.zip';
}


/// Timeouts (milliseconds)
class Timeouts {
  static const int defaultTimeout = 30000;
  static const int voiceInit = 15000;
}

const List<String> kObservationCategories = [
  'General',
  'Fire Safety',
  'Electrical',
  'Structural',
  'Egress',
  'Hazmat',
  'Access',
];
