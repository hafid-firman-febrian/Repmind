import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/config/env.dart';

void main() {
  group('Env.missingKeys', () {
    test('returns nothing when every value is set', () {
      expect(Env.missingKeys({'A': 'x', 'B': 'y'}), isEmpty);
    });

    test('lists keys that are empty or only whitespace', () {
      expect(Env.missingKeys({'A': '', 'B': 'y', 'C': '  '}), ['A', 'C']);
    });
  });
}
