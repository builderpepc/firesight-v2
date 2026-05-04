import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root providers and service locator helpers.
void initializeProviders() {
  // TODO: Register all app-level providers here.
  // Firebase is initialized in main.dart via Firebase.initializeApp();
}

/// Wrapper for Firebase initialization state.
final firebaseInitializedProvider = Provider<bool>((ref) => false);
