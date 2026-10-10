import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/profile/domain/models/equipment.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/domain/models/fitness_level.dart';
import 'package:repmind/features/profile/presentation/states/profile_draft.dart';

import '../../../fixtures/profile_fixtures.dart';

void main() {
  const complete = ProfileDraft(
    goal: FitnessGoal.buildMuscle,
    level: FitnessLevel.intermediate,
    equipment: {Equipment.dumbbell},
    daysPerWeek: 4,
    weightText: '72,5',
    heightText: '175',
  );

  test('toDetails is null until every answer is valid', () {
    expect(const ProfileDraft().toDetails(), isNull);
    expect(complete.copyWith(heightText: '90').toDetails(), isNull);
  });

  test('toDetails parses comma decimals', () {
    final details = complete.toDetails()!;
    expect(details.weightKg, 72.5);
    expect(details.heightCm, 175);
    expect(details.daysPerWeek, 4);
  });

  test('toggleEquipment adds and removes', () {
    final added = complete.toggleEquipment(Equipment.bench);
    expect(added.equipment, {Equipment.dumbbell, Equipment.bench});
    expect(added.toggleEquipment(Equipment.dumbbell).equipment, {
      Equipment.bench,
    });
  });

  test('withDaysPerWeek stays inside 2–6', () {
    expect(complete.withDaysPerWeek(1).daysPerWeek, 2);
    expect(complete.withDaysPerWeek(7).daysPerWeek, 6);
  });

  test('fromDetails prefills text fields without trailing .0', () {
    final draft = ProfileDraft.fromDetails(sampleDetails);
    expect(draft.weightText, '72.5');
    expect(draft.heightText, '175');
    expect(draft.goal, FitnessGoal.buildMuscle);
  });
}
