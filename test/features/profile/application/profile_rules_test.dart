import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/profile/application/services/profile_rules.dart';

void main() {
  group('parseDecimal', () {
    test('accepts dot and comma decimals', () {
      expect(ProfileRules.parseDecimal('72.5'), 72.5);
      expect(ProfileRules.parseDecimal('72,5'), 72.5);
      expect(ProfileRules.parseDecimal(' 80 '), 80);
    });

    test('rejects empty and non-numeric input', () {
      expect(ProfileRules.parseDecimal(''), isNull);
      expect(ProfileRules.parseDecimal('abc'), isNull);
      expect(ProfileRules.parseDecimal('1,234.5'), isNull);
    });

    test('rejects non-finite values', () {
      expect(ProfileRules.parseDecimal('NaN'), isNull);
      expect(ProfileRules.parseDecimal('Infinity'), isNull);
    });
  });

  group('validateWeight', () {
    test('accepts values inside 25–350 kg', () {
      expect(ProfileRules.validateWeight('25'), isNull);
      expect(ProfileRules.validateWeight('72,5'), isNull);
      expect(ProfileRules.validateWeight('350'), isNull);
    });

    test('rejects NaN as a weight', () {
      expect(ProfileRules.validateWeight('NaN'), isNotNull);
    });

    test('explains empty and out-of-range values', () {
      expect(ProfileRules.validateWeight(''), 'Enter your weight in kg.');
      expect(
        ProfileRules.validateWeight('24.9'),
        'Enter a weight between 25 and 350 kg.',
      );
    });
  });

  group('validateHeight', () {
    test('accepts values inside 100–250 cm', () {
      expect(ProfileRules.validateHeight('175'), isNull);
    });

    test('explains out-of-range values', () {
      expect(
        ProfileRules.validateHeight('90'),
        'Enter a height between 100 and 250 cm.',
      );
    });
  });

  test('formatDecimal drops a trailing .0', () {
    expect(ProfileRules.formatDecimal(175), '175');
    expect(ProfileRules.formatDecimal(72.5), '72.5');
  });

  test('formatWeight appends kg', () {
    expect(ProfileRules.formatWeight(72.5), '72.5 kg');
    expect(ProfileRules.formatWeight(80), '80 kg');
  });

  test('formatHeight appends cm', () {
    expect(ProfileRules.formatHeight(175), '175 cm');
    expect(ProfileRules.formatHeight(175.5), '175.5 cm');
  });
}
