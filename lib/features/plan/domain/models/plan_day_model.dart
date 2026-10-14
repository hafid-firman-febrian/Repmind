import 'plan_exercise_model.dart';
import 'workout_focus.dart';

class PlanDay {
  const PlanDay({
    required this.id,
    required this.dayNumber,
    required this.weekday,
    required this.title,
    required this.focus,
    required this.estimatedMinutes,
    required this.exercises,
  });

  final String id;
  final int dayNumber;
  final int weekday;
  final String title;
  final WorkoutFocus focus;
  final int estimatedMinutes;
  final List<PlanExercise> exercises;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final exercises = [
      for (final row in json['plan_exercises'] as List<dynamic>)
        PlanExercise.fromJson(row as Map<String, dynamic>),
    ]..sort((a, b) => a.position.compareTo(b.position));
    return PlanDay(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      weekday: json['weekday'] as int,
      title: json['title'] as String,
      focus: WorkoutFocus.fromDb(json['focus'] as String),
      estimatedMinutes: json['estimated_minutes'] as int,
      exercises: exercises,
    );
  }
}
