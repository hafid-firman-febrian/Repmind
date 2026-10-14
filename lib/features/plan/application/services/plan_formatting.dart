import '../../domain/models/exercise_model.dart';
import '../../domain/models/plan_day_model.dart';
import '../../domain/models/plan_exercise_model.dart';

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

String weekdayName(int weekday) => _weekdayNames[weekday - 1];

String weekdayShort(int weekday) => weekdayName(weekday).substring(0, 3);

String equipmentSummary(PlanDay day) {
  final labels = <String>[];
  for (final planExercise in day.exercises) {
    for (final item in planExercise.exercise.equipment) {
      if (!labels.contains(item.label)) labels.add(item.label);
    }
  }
  if (labels.isEmpty) return 'Bodyweight';
  return labels.take(2).join(', ');
}

String dayMeta(PlanDay day) =>
    '${_exerciseCount(day)} · ~${day.estimatedMinutes} min · ${equipmentSummary(day)}';

String daySubtitle(PlanDay day) =>
    '${day.focus.label} · ${_exerciseCount(day)}';

String dayWatermark(PlanDay day) => day.dayNumber.toString().padLeft(2, '0');

String exerciseDose(PlanExercise planExercise) =>
    '${planExercise.sets} × ${planExercise.reps.replaceAll('-', '–')}';

String restLabel(PlanExercise planExercise) =>
    'Rest ${planExercise.restSeconds}s';

String exerciseDetail(Exercise exercise) {
  final equipment = exercise.equipment.isEmpty
      ? 'Bodyweight'
      : exercise.equipment.map((item) => item.label).join(', ');
  return '${exercise.primaryMuscle} · $equipment';
}

String _exerciseCount(PlanDay day) {
  final count = day.exercises.length;
  return count == 1 ? '1 exercise' : '$count exercises';
}
