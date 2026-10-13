enum Equipment {
  dumbbell('dumbbell', 'Dumbbells'),
  barbell('barbell', 'Barbell'),
  kettlebell('kettlebell', 'Kettlebell'),
  resistanceBand('resistance_band', 'Resistance band'),
  pullUpBar('pull_up_bar', 'Pull-up bar'),
  bench('bench', 'Bench'),
  machine('machine', 'Gym machines');

  const Equipment(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static Equipment fromDb(String value) =>
      values.firstWhere((item) => item.dbValue == value);
}
