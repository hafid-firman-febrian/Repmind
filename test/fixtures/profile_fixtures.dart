import 'package:repmind/features/profile/domain/models/equipment.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/domain/models/fitness_level.dart';
import 'package:repmind/features/profile/domain/models/profile_details.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';

Map<String, dynamic> profileRow({
  String id = 'user-1',
  bool onboarded = true,
}) => {
  'id': id,
  'display_name': 'Alex',
  'avatar_url': null,
  'goal': onboarded ? 'build_muscle' : null,
  'level': onboarded ? 'intermediate' : null,
  'equipment': onboarded ? ['dumbbell', 'bench'] : <String>[],
  'days_per_week': onboarded ? 4 : null,
  'weight_kg': onboarded ? 72.5 : null,
  'height_cm': onboarded ? 175 : null,
  'onboarded_at': onboarded ? '2026-09-30T08:00:00+00:00' : null,
  'ai_model': 'gemini_flash',
  'created_at': '2026-09-30T07:00:00+00:00',
  'updated_at': '2026-09-30T08:00:00+00:00',
};

Profile sampleProfile({bool onboarded = true}) =>
    Profile.fromJson(profileRow(onboarded: onboarded));

const sampleDetails = ProfileDetails(
  goal: FitnessGoal.buildMuscle,
  level: FitnessLevel.intermediate,
  equipment: {Equipment.dumbbell, Equipment.bench},
  daysPerWeek: 4,
  weightKg: 72.5,
  heightCm: 175,
);
