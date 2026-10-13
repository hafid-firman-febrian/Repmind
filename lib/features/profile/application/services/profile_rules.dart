abstract final class ProfileRules {
  static const minDaysPerWeek = 2;
  static const maxDaysPerWeek = 6;
  static const minWeightKg = 25.0;
  static const maxWeightKg = 350.0;
  static const minHeightCm = 100.0;
  static const maxHeightCm = 250.0;

  static double? parseDecimal(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) return null;
    return value;
  }

  static String? validateWeight(String input) => _validateRange(
    input,
    field: 'weight',
    unit: 'kg',
    min: minWeightKg,
    max: maxWeightKg,
  );

  static String? validateHeight(String input) => _validateRange(
    input,
    field: 'height',
    unit: 'cm',
    min: minHeightCm,
    max: maxHeightCm,
  );

  static String formatDecimal(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  static String formatWeight(double kilograms) =>
      '${formatDecimal(kilograms)} kg';

  static String formatHeight(double centimeters) =>
      '${formatDecimal(centimeters)} cm';

  static String? _validateRange(
    String input, {
    required String field,
    required String unit,
    required double min,
    required double max,
  }) {
    final value = parseDecimal(input);
    if (value == null) return 'Enter your $field in $unit.';
    if (value < min || value > max) {
      return 'Enter a $field between ${formatDecimal(min)} and ${formatDecimal(max)} $unit.';
    }
    return null;
  }
}
