import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/plan/application/services/week_schedule.dart';

import '../../../fixtures/plan_fixtures.dart';

void main() {
  final plan = samplePlan();

  group('upcomingWorkout', () {
    test('is today when today is a training day', () {
      final upcoming = upcomingWorkout(plan, DateTime(2026, 10, 13, 9))!;

      expect(upcoming.day.dayNumber, 2);
      expect(upcoming.isToday, isTrue);
    });

    test('is the next training day on a rest day', () {
      final upcoming = upcomingWorkout(plan, DateTime(2026, 10, 14, 9))!;

      expect(upcoming.day.dayNumber, 3);
      expect(upcoming.isToday, isFalse);
    });

    test('wraps from Sunday to Monday', () {
      final upcoming = upcomingWorkout(plan, DateTime(2026, 10, 18, 9))!;

      expect(upcoming.day.dayNumber, 1);
      expect(upcoming.isToday, isFalse);
    });

    test('Saturday is the last training day of the week', () {
      final upcoming = upcomingWorkout(plan, DateTime(2026, 10, 17, 20))!;

      expect(upcoming.day.dayNumber, 4);
      expect(upcoming.isToday, isTrue);
    });
  });

  test('weekSchedule marks training days and today', () {
    final week = weekSchedule(plan, DateTime(2026, 10, 13, 9));

    expect(week.map((day) => day.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(week.where((day) => day.isScheduled).map((day) => day.weekday), [
      1,
      2,
      4,
      6,
    ]);
    expect(week.where((day) => day.isToday).map((day) => day.weekday), [2]);
  });

  test('dayByNumber finds a day or returns null', () {
    expect(dayByNumber(plan, 3)!.title, 'Legs & Core');
    expect(dayByNumber(plan, 9), isNull);
  });
}
