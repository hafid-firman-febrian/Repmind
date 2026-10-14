import '../../domain/models/plan_day_model.dart';
import '../../domain/models/workout_plan_model.dart';

class UpcomingWorkout {
  const UpcomingWorkout({required this.day, required this.isToday});

  final PlanDay day;
  final bool isToday;
}

class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.isScheduled,
    required this.isToday,
  });

  final int weekday;
  final bool isScheduled;
  final bool isToday;
}

UpcomingWorkout? upcomingWorkout(WorkoutPlan plan, DateTime now) {
  for (var offset = 0; offset < DateTime.daysPerWeek; offset++) {
    final weekday = (now.weekday - 1 + offset) % DateTime.daysPerWeek + 1;
    for (final day in plan.days) {
      if (day.weekday == weekday) {
        return UpcomingWorkout(day: day, isToday: offset == 0);
      }
    }
  }
  return null;
}

List<ScheduleDay> weekSchedule(WorkoutPlan plan, DateTime now) => [
  for (var weekday = 1; weekday <= DateTime.daysPerWeek; weekday++)
    ScheduleDay(
      weekday: weekday,
      isScheduled: plan.days.any((day) => day.weekday == weekday),
      isToday: weekday == now.weekday,
    ),
];

PlanDay? dayByNumber(WorkoutPlan plan, int dayNumber) {
  for (final day in plan.days) {
    if (day.dayNumber == dayNumber) return day;
  }
  return null;
}
