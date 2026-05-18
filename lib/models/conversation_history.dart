/// A single turn in a voice conversation.
class ConversationTurn {
  const ConversationTurn({required this.role, required this.content});

  /// Either `'user'` or `'assistant'`.
  final String role;

  /// The text content. User turns in Tier 2 (audio-only) use the sentinel
  /// value [kAudioPlaceholder] since no transcript is available.
  final String content;

  static const kAudioPlaceholder = '[audio]';

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Mutable conversation history shared across agent instances.
///
/// Passed into [VoiceAgent.startListening] so history survives agent
/// recreation on tier switches or stop/restart cycles.
class ConversationHistory {
  final List<ConversationTurn> turns = [];

  bool get isEmpty => turns.isEmpty;

  void addUser(String content) =>
      turns.add(ConversationTurn(role: 'user', content: content));

  void addAssistant(String content) =>
      turns.add(ConversationTurn(role: 'assistant', content: content));

  /// Returns all turns as a JSON-compatible list for inclusion in a
  /// messages array (e.g. for Cactus or Gemma).
  List<Map<String, dynamic>> toJsonList() =>
      turns.map((t) => t.toJson()).toList();

  /// Formats history as a readable block for injection into a system prompt.
  ///
  /// User turns with real text (e.g. from Gemini transcription) are included as
  /// "Inspector: <text>". Audio-only placeholders ([kAudioPlaceholder]) are
  /// omitted since the literal string "[audio]" adds no context; the paired
  /// assistant response provides enough context for the model to infer the topic.
  String toSystemPromptBlock() {
    if (turns.isEmpty) return '';
    final lines = <String>[];
    for (int i = 0; i < turns.length; i++) {
      final t = turns[i];
      if (t.role == 'user') {
        if (t.content != ConversationTurn.kAudioPlaceholder) {
          lines.add('Inspector: ${t.content}');
        }
        // Skip audio placeholder — next assistant turn provides the context.
      } else {
        lines.add('Assistant: ${t.content}');
      }
    }
    if (lines.isEmpty) return '';
    return '\nPrior conversation:\n${lines.join('\n')}';
  }

  void clear() => turns.clear();
}
