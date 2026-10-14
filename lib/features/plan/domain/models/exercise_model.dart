import '../../../profile/domain/models/equipment.dart';
import 'workout_focus.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.focus,
    required this.primaryMuscle,
    required this.equipment,
  });

  final String id;
  final String name;
  final WorkoutFocus focus;
  final String primaryMuscle;
  final List<Equipment> equipment;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    focus: WorkoutFocus.fromDb(json['focus'] as String),
    primaryMuscle: json['primary_muscle'] as String,
    equipment: [
      for (final value in json['equipment'] as List<dynamic>)
        Equipment.fromDb(value as String),
    ],
  );
}
