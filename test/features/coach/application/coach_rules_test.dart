import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/application/services/coach_rules.dart';

void main() {
  test('rejects empty, blank and over-long messages', () {
    for (final raw in ['', '   ', 'x' * 1001]) {
      expect(CoachRules.canSend(raw), isFalse, reason: raw.length.toString());
    }
  });

  test('accepts short messages and messages of exactly 1000 characters', () {
    expect(CoachRules.canSend('Hi'), isTrue);
    expect(CoachRules.canSend('x' * 1000), isTrue);
  });

  test('offers the three suggestions', () {
    expect(CoachRules.suggestions, [
      'What should I focus on today?',
      'My shoulder feels tight today',
      'How heavy should I go?',
    ]);
  });
}
