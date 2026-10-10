import '../../application/services/profile_rules.dart';
import '../../domain/models/equipment.dart';
import '../../domain/models/fitness_goal.dart';
import '../../domain/models/fitness_level.dart';
import '../../domain/models/profile_details.dart';

class ProfileDraft {
  const ProfileDraft({
    this.goal,
    this.level,
    this.equipment = const {},
    this.daysPerWeek = 3,
    this.weightText = '',
    this.heightText = '',
  });

  factory ProfileDraft.fromDetails(ProfileDetails details) => ProfileDraft(
    goal: details.goal,
    level: details.level,
    equipment: details.equipment,
    daysPerWeek: details.daysPerWeek,
    weightText: ProfileRules.formatDecimal(details.weightKg),
    heightText: ProfileRules.formatDecimal(details.heightCm),
  );

  final FitnessGoal? goal;
  final FitnessLevel? level;
  final Set<Equipment> equipment;
  final int daysPerWeek;
  final String weightText;
  final String heightText;

  String? get weightError => ProfileRules.validateWeight(weightText);
  String? get heightError => ProfileRules.validateHeight(heightText);
  bool get hasValidBody => weightError == null && heightError == null;

  ProfileDetails? toDetails() {
    final goal = this.goal;
    final level = this.level;
    final weightKg = ProfileRules.parseDecimal(weightText);
    final heightCm = ProfileRules.parseDecimal(heightText);
    if (goal == null ||
        level == null ||
        !hasValidBody ||
        weightKg == null ||
        heightCm == null) {
      return null;
    }
    return ProfileDetails(
      goal: goal,
      level: level,
      equipment: equipment,
      daysPerWeek: daysPerWeek,
      weightKg: weightKg,
      heightCm: heightCm,
    );
  }

  ProfileDraft toggleEquipment(Equipment item) {
    final next = {...equipment};
    if (!next.remove(item)) next.add(item);
    return copyWith(equipment: next);
  }

  ProfileDraft withDaysPerWeek(int days) => copyWith(
    daysPerWeek: days.clamp(
      ProfileRules.minDaysPerWeek,
      ProfileRules.maxDaysPerWeek,
    ),
  );

  ProfileDraft copyWith({
    FitnessGoal? goal,
    FitnessLevel? level,
    Set<Equipment>? equipment,
    int? daysPerWeek,
    String? weightText,
    String? heightText,
  }) => ProfileDraft(
    goal: goal ?? this.goal,
    level: level ?? this.level,
    equipment: equipment ?? this.equipment,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    weightText: weightText ?? this.weightText,
    heightText: heightText ?? this.heightText,
  );
}
