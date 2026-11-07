import '../../../plan/domain/models/workout_plan_model.dart';
import '../../../profile/domain/models/fitness_goal.dart';

String chatContextLabel(WorkoutPlan? plan, FitnessGoal goal) {
  final prefix = plan == null ? 'No plan yet' : 'Using plan v${plan.version}';
  return '$prefix · ${goal.label}';
}
