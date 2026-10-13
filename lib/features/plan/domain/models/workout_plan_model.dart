import '../../../profile/domain/models/ai_model.dart';
import '../../../profile/domain/models/fitness_goal.dart';
import '../../../profile/domain/models/fitness_level.dart';
import 'plan_day_model.dart';

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.version,
    required this.title,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.aiModel,
    required this.instruction,
    required this.createdAt,
    required this.days,
  });

  final String id;
  final int version;
  final String title;
  final FitnessGoal goal;
  final FitnessLevel level;
  final int daysPerWeek;
  final AiModel aiModel;
  final String? instruction;
  final DateTime createdAt;
  final List<PlanDay> days;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final days = [
      for (final row in json['plan_days'] as List<dynamic>)
        PlanDay.fromJson(row as Map<String, dynamic>),
    ]..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return WorkoutPlan(
      id: json['id'] as String,
      version: json['version'] as int,
      title: json['title'] as String,
      goal: FitnessGoal.fromDb(json['goal'] as String)!,
      level: FitnessLevel.fromDb(json['level'] as String)!,
      daysPerWeek: json['days_per_week'] as int,
      aiModel: AiModel.fromDb(json['ai_model'] as String),
      instruction: json['instruction'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      days: days,
    );
  }
}
