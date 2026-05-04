import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceAgentSelector', () {
    test('creates GeminiVoiceAgent when online', () {
      // TODO: Mock ConnectivityService to emit true and verify agent type.
    });

    test('creates NativeFallbackAgent when offline', () {
      // TODO: Mock ConnectivityService to emit false and verify agent type.
    });
  });
}
