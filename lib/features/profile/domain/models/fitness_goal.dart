enum FitnessGoal {
  loseWeight(
    'lose_weight',
    'Lose weight',
    'Burn fat and build healthy habits.',
  ),
  buildMuscle(
    'build_muscle',
    'Build muscle',
    'Get stronger and add lean muscle.',
  ),
  stayFit('stay_fit', 'Stay fit', 'Keep moving and feel good every day.');

  const FitnessGoal(this.dbValue, this.label, this.description);

  final String dbValue;
  final String label;
  final String description;

  static FitnessGoal? fromDb(String? value) =>
      value == null ? null : values.firstWhere((goal) => goal.dbValue == value);
}
