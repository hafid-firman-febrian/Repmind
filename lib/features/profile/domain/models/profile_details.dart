import 'equipment.dart';
import 'fitness_goal.dart';
import 'fitness_level.dart';

class ProfileDetails {
  const ProfileDetails({
    required this.goal,
    required this.level,
    required this.equipment,
    required this.daysPerWeek,
    required this.weightKg,
    required this.heightCm,
  });

  final FitnessGoal goal;
  final FitnessLevel level;
  final Set<Equipment> equipment;
  final int daysPerWeek;
  final double weightKg;
  final double heightCm;

  Map<String, dynamic> toJson() => {
    'goal': goal.dbValue,
    'level': level.dbValue,
    'equipment': [
      for (final item in Equipment.values)
        if (equipment.contains(item)) item.dbValue,
    ],
    'days_per_week': daysPerWeek,
    'weight_kg': weightKg,
    'height_cm': heightCm,
  };
}
