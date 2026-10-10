double calculateBmi({required double weightKg, required double heightCm}) {
  final heightM = heightCm / 100;
  final bmi = weightKg / (heightM * heightM);
  return (bmi * 10).roundToDouble() / 10;
}
