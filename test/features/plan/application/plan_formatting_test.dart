import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/plan/application/services/plan_formatting.dart';
import 'package:repmind/features/plan/domain/models/plan_day_model.dart';

import '../../../fixtures/plan_fixtures.dart';

void main() {
  final plan = samplePlan();
  final lowerDay = plan.days[0];
  final pushDay = plan.days[1];
  final coreDay = plan.days[2];

  test('weekday names', () {
    expect(weekdayName(1), 'Monday');
    expect(weekdayName(7), 'Sunday');
    expect(weekdayShort(4), 'Thu');
  });

  test('equipmentSummary lists up to two items in exercise order', () {
    expect(equipmentSummary(pushDay), 'Dumbbells, Bench');
    expect(equipmentSummary(lowerDay), 'Dumbbells');
  });

  test('equipmentSummary falls back to bodyweight', () {
    final day = PlanDay.fromJson(
      planDayRow(
        dayNumber: 1,
        weekday: 1,
        title: 'Bodyweight Basics',
        focus: 'full_body',
        minutes: 30,
        exercises: [
          planExerciseRow(1, exerciseRow('push_up', 'Push-up')),
          planExerciseRow(2, exerciseRow('plank', 'Plank', focus: 'core')),
        ],
      ),
    );

    expect(equipmentSummary(day), 'Bodyweight');
  });

  test('day labels', () {
    expect(dayMeta(pushDay), '6 exercises · ~45 min · Dumbbells, Bench');
    expect(dayMeta(lowerDay), '5 exercises · ~50 min · Dumbbells');
    expect(daySubtitle(coreDay), 'Core · 5 exercises');
    expect(dayWatermark(pushDay), '02');
  });

  test('exercise labels', () {
    final bench = pushDay.exercises[0];
    final plank = coreDay.exercises[1];

    expect(exerciseDose(bench), '4 × 8–10');
    expect(exerciseDose(plank), '3 × 30–45s');
    expect(exerciseDose(pushDay.exercises[2]), '3 × 12');
    expect(restLabel(bench), 'Rest 90s');
    expect(exerciseDetail(bench.exercise), 'Chest · Dumbbells, Bench');
    expect(exerciseDetail(plank.exercise), 'Core · Bodyweight');
  });
}
