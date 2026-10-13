enum FitnessLevel {
  beginner(
    'beginner',
    'Beginner',
    'New to training or coming back after a long break.',
  ),
  intermediate(
    'intermediate',
    'Intermediate',
    'Training regularly for six months or more.',
  ),
  advanced('advanced', 'Advanced', 'Years of consistent, structured training.');

  const FitnessLevel(this.dbValue, this.label, this.description);

  final String dbValue;
  final String label;
  final String description;

  static FitnessLevel? fromDb(String? value) => value == null
      ? null
      : values.firstWhere((level) => level.dbValue == value);
}
