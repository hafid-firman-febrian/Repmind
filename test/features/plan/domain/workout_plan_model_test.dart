import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/plan/domain/models/workout_focus.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/domain/models/equipment.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/domain/models/fitness_level.dart';

import '../../../fixtures/plan_fixtures.dart';

void main() {
  test('reads the plan columns', () {
    final plan = WorkoutPlan.fromJson(
      workoutPlanRow(version: 2, instruction: 'More core work'),
    );

    expect(plan.id, 'plan-2');
    expect(plan.version, 2);
    expect(plan.title, '4-Day Upper / Lower');
    expect(plan.goal, FitnessGoal.buildMuscle);
    expect(plan.level, FitnessLevel.intermediate);
    expect(plan.daysPerWeek, 4);
    expect(plan.aiModel, AiModel.geminiFlash);
    expect(plan.instruction, 'More core work');
    expect(plan.createdAt, DateTime.utc(2026, 10, 13, 8));
  });

  test('reads days with their nested exercises', () {
    final day = samplePlan().days[1];
    final first = day.exercises.first;

    expect(day.dayNumber, 2);
    expect(day.weekday, 2);
    expect(day.title, 'Upper Body Push');
    expect(day.focus, WorkoutFocus.upper);
    expect(day.estimatedMinutes, 45);
    expect(day.exercises, hasLength(6));
    expect(first.position, 1);
    expect(first.sets, 4);
    expect(first.reps, '8-10');
    expect(first.restSeconds, 90);
    expect(first.exercise.name, 'Dumbbell Bench Press');
    expect(first.exercise.primaryMuscle, 'Chest');
    expect(first.exercise.equipment, [Equipment.dumbbell, Equipment.bench]);
  });

  test('sorts days by day number and exercises by position', () {
    final rows = sampleDayRows().reversed.map((day) {
      final exercises = (day['plan_exercises'] as List<Map<String, dynamic>>)
          .reversed
          .toList();
      return {...day, 'plan_exercises': exercises};
    }).toList();

    final plan = WorkoutPlan.fromJson(workoutPlanRow(days: rows));

    expect(plan.days.map((day) => day.dayNumber), [1, 2, 3, 4]);
    expect(plan.days.first.exercises.map((e) => e.position), [1, 2, 3, 4, 5]);
  });

  test('maps snake_case focus values', () {
    expect(WorkoutFocus.fromDb('full_body'), WorkoutFocus.fullBody);
    expect(WorkoutFocus.fullBody.label, 'Full body');
  });

  test('AiModel maps database keys to labels', () {
    expect(AiModel.fromDb('gemini_flash_lite'), AiModel.geminiFlashLite);
    expect(AiModel.geminiFlash.label, 'Gemini 3.8 Flash');
    expect(AiModel.geminiPro.description, 'Best reasoning · slower');
  });
}
