abstract final class CoachRules {
  static const maxMessageLength = 1000;

  static const suggestions = [
    'What should I focus on today?',
    'My shoulder feels tight today',
    'How heavy should I go?',
  ];

  static bool canSend(String raw) {
    final length = raw.trim().length;
    return length > 0 && length <= maxMessageLength;
  }
}
