import 'exercise_model.dart';

class PlanExercise {
  const PlanExercise({
    required this.position,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final int position;
  final Exercise exercise;
  final int sets;
  final String reps;
  final int restSeconds;

  factory PlanExercise.fromJson(Map<String, dynamic> json) => PlanExercise(
    position: json['position'] as int,
    exercise: Exercise.fromJson(json['exercises'] as Map<String, dynamic>),
    sets: json['sets'] as int,
    reps: json['reps'] as String,
    restSeconds: json['rest_seconds'] as int,
  );
}
