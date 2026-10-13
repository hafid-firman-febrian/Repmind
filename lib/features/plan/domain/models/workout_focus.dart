enum WorkoutFocus {
  upper('upper', 'Upper'),
  lower('lower', 'Lower'),
  core('core', 'Core'),
  fullBody('full_body', 'Full body');

  const WorkoutFocus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static WorkoutFocus fromDb(String value) =>
      values.firstWhere((focus) => focus.dbValue == value);
}
