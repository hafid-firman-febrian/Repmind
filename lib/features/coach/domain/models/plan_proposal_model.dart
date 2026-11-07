class PlanChange {
  const PlanChange({
    required this.fromExerciseId,
    required this.toExerciseId,
    required this.toExerciseName,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final String fromExerciseId;
  final String toExerciseId;
  final String toExerciseName;
  final int sets;
  final String reps;
  final int restSeconds;

  factory PlanChange.fromJson(Map<String, dynamic> json) => PlanChange(
    fromExerciseId: json['from_exercise_id'] as String,
    toExerciseId: json['to_exercise_id'] as String,
    toExerciseName: json['to_exercise_name'] as String,
    sets: json['sets'] as int,
    reps: json['reps'] as String,
    restSeconds: json['rest_seconds'] as int,
  );
}

class PlanProposal {
  const PlanProposal({
    required this.basedOnPlanId,
    required this.dayNumber,
    required this.summary,
    required this.changes,
  });

  final String basedOnPlanId;
  final int dayNumber;
  final String summary;
  final List<PlanChange> changes;

  factory PlanProposal.fromJson(Map<String, dynamic> json) => PlanProposal(
    basedOnPlanId: json['based_on_plan_id'] as String,
    dayNumber: json['day_number'] as int,
    summary: json['summary'] as String,
    changes: [
      for (final change in json['changes'] as List<dynamic>)
        PlanChange.fromJson(change as Map<String, dynamic>),
    ],
  );
}
