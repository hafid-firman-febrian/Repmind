import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/week_strip.dart';
import '../../../plan/application/services/plan_formatting.dart';
import '../../../plan/application/services/week_schedule.dart';
import '../../../plan/domain/models/workout_plan_model.dart';

class ThisWeekCard extends StatelessWidget {
  const ThisWeekCard({super.key, required this.plan, required this.now});

  final WorkoutPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RepmindRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('This week', style: text.subtitle)),
              Text(
                '${plan.days.length} workouts',
                style: text.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WeekStrip(
            items: [
              for (final day in weekSchedule(plan, now))
                WeekStripItem(
                  dayName: weekdayName(day.weekday),
                  status: day.isScheduled
                      ? WeekStripStatus.scheduled
                      : WeekStripStatus.rest,
                  isToday: day.isToday,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
