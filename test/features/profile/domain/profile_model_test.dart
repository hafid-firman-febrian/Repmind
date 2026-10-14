import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/domain/models/equipment.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/domain/models/fitness_level.dart';
import 'package:repmind/features/profile/domain/models/profile_details.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';

import '../../../fixtures/profile_fixtures.dart';

void main() {
  group('Profile.fromJson', () {
    test('reads the chosen AI model', () {
      expect(Profile.fromJson(profileRow()).aiModel, AiModel.geminiFlash);
      expect(
        Profile.fromJson({...profileRow(), 'ai_model': 'gemini_pro'}).aiModel,
        AiModel.geminiPro,
      );
    });

    test('reads an onboarded row with snake_case columns', () {
      final profile = Profile.fromJson(profileRow());

      expect(profile.id, 'user-1');
      expect(profile.displayName, 'Alex');
      expect(profile.goal, FitnessGoal.buildMuscle);
      expect(profile.level, FitnessLevel.intermediate);
      expect(profile.equipment, [Equipment.dumbbell, Equipment.bench]);
      expect(profile.daysPerWeek, 4);
      expect(profile.weightKg, 72.5);
      expect(profile.onboardedAt, DateTime.utc(2026, 9, 30, 8));
      expect(profile.isOnboarded, isTrue);
    });

    test('reads integer numerics as doubles', () {
      expect(Profile.fromJson(profileRow()).heightCm, 175.0);
    });

    test('reads a fresh row created by the signup trigger', () {
      final profile = Profile.fromJson(profileRow(onboarded: false));

      expect(profile.goal, isNull);
      expect(profile.equipment, isEmpty);
      expect(profile.isOnboarded, isFalse);
      expect(profile.details, isNull);
    });

    test('exposes complete details once onboarded', () {
      final details = Profile.fromJson(profileRow()).details!;

      expect(details.goal, FitnessGoal.buildMuscle);
      expect(details.equipment, {Equipment.dumbbell, Equipment.bench});
      expect(details.heightCm, 175);
    });
  });

  test('ProfileDetails.toJson writes database values in enum order', () {
    const details = ProfileDetails(
      goal: FitnessGoal.loseWeight,
      level: FitnessLevel.beginner,
      equipment: {Equipment.pullUpBar, Equipment.resistanceBand},
      daysPerWeek: 3,
      weightKg: 80.5,
      heightCm: 180,
    );

    expect(details.toJson(), {
      'goal': 'lose_weight',
      'level': 'beginner',
      'equipment': ['resistance_band', 'pull_up_bar'],
      'days_per_week': 3,
      'weight_kg': 80.5,
      'height_cm': 180.0,
    });
  });

  test('enums round-trip through their database values', () {
    for (final goal in FitnessGoal.values) {
      expect(FitnessGoal.fromDb(goal.dbValue), goal);
    }
    for (final level in FitnessLevel.values) {
      expect(FitnessLevel.fromDb(level.dbValue), level);
    }
    for (final item in Equipment.values) {
      expect(Equipment.fromDb(item.dbValue), item);
    }
    expect(FitnessGoal.fromDb(null), isNull);
  });
}
