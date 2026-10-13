import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../../../../core/widgets/tag_badge.dart';
import '../../../plan/application/services/plan_formatting.dart';
import '../../../plan/application/services/week_schedule.dart';
import '../../../plan/domain/models/workout_plan_model.dart';

class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key, required this.plan, required this.now});

  final WorkoutPlan plan;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final upcoming = upcomingWorkout(plan, now);
    if (upcoming == null) return const SizedBox.shrink();
    final day = upcoming.day;
    final badge = upcoming.isToday
        ? 'AI plan · Day ${day.dayNumber} of ${plan.days.length}'
        : 'AI plan · Next · ${weekdayShort(day.weekday)}';

    return HeroCard(
      badge: TagBadge(label: badge, showSparkle: true),
      title: day.title,
      meta: dayMeta(day),
      watermark: dayWatermark(day),
      footer: Align(
        alignment: Alignment.centerRight,
        child: SquareIconButton(
          icon: Icons.play_arrow_rounded,
          tooltip: 'Open workout',
          onPressed: () =>
              context.push(AppRoutes.workoutDayPath(day.dayNumber)),
        ),
      ),
    );
  }
}
