import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/profile/application/services/body_metrics.dart';

void main() {
  test('calculates BMI rounded to one decimal', () {
    expect(calculateBmi(weightKg: 70, heightCm: 175), 22.9);
    expect(calculateBmi(weightKg: 72.5, heightCm: 175), 23.7);
  });
}
