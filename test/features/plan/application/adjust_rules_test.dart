import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/plan/application/services/adjust_rules.dart';

void main() {
  test('rejects empty, blank and too short instructions', () {
    for (final raw in ['', '   ', 'ab', '  ab  ']) {
      expect(AdjustRules.validateInstruction(raw), isNotNull, reason: raw);
    }
  });

  test('accepts instructions of 3 to 200 characters after trimming', () {
    expect(AdjustRules.validateInstruction('abc'), isNull);
    expect(AdjustRules.validateInstruction('  More core work  '), isNull);
    expect(AdjustRules.validateInstruction('x' * 200), isNull);
  });

  test('rejects instructions over 200 characters', () {
    expect(AdjustRules.validateInstruction('x' * 201), isNotNull);
  });

  test('offers four suggestions', () {
    expect(AdjustRules.suggestions, [
      'Shorter sessions',
      'More core work',
      'No barbell',
      'Swap leg day to Friday',
    ]);
  });
}
