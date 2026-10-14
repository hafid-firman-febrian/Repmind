import 'ai_model.dart';
import 'equipment.dart';
import 'fitness_goal.dart';
import 'fitness_level.dart';
import 'profile_details.dart';

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.goal,
    required this.level,
    required this.equipment,
    required this.daysPerWeek,
    required this.weightKg,
    required this.heightCm,
    required this.onboardedAt,
    required this.aiModel,
  });

  final String id;
  final String? displayName;
  final String? avatarUrl;
  final FitnessGoal? goal;
  final FitnessLevel? level;
  final List<Equipment> equipment;
  final int? daysPerWeek;
  final double? weightKg;
  final double? heightCm;
  final DateTime? onboardedAt;
  final AiModel aiModel;

  bool get isOnboarded => onboardedAt != null;

  ProfileDetails? get details {
    final goal = this.goal;
    final level = this.level;
    final daysPerWeek = this.daysPerWeek;
    final weightKg = this.weightKg;
    final heightCm = this.heightCm;
    if (goal == null ||
        level == null ||
        daysPerWeek == null ||
        weightKg == null ||
        heightCm == null) {
      return null;
    }
    return ProfileDetails(
      goal: goal,
      level: level,
      equipment: equipment.toSet(),
      daysPerWeek: daysPerWeek,
      weightKg: weightKg,
      heightCm: heightCm,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final onboardedAt = json['onboarded_at'] as String?;
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      goal: FitnessGoal.fromDb(json['goal'] as String?),
      level: FitnessLevel.fromDb(json['level'] as String?),
      equipment: [
        for (final value
            in json['equipment'] as List<dynamic>? ?? const <dynamic>[])
          Equipment.fromDb(value as String),
      ],
      daysPerWeek: json['days_per_week'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      onboardedAt: onboardedAt == null ? null : DateTime.parse(onboardedAt),
      aiModel: AiModel.fromDb(json['ai_model'] as String),
    );
  }
}
