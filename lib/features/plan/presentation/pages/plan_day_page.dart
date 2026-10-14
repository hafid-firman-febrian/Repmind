import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../../../../core/widgets/tag_badge.dart';
import '../../application/services/plan_formatting.dart';
import '../../application/services/week_schedule.dart';
import '../controllers/active_plan_controller.dart';
import '../widgets/exercise_row.dart';

class PlanDayPage extends ConsumerWidget {
  const PlanDayPage({super.key, required this.dayNumber});

  final int? dayNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(activePlanControllerProvider);
    final plan = planState.value;
    final dayNumber = this.dayNumber;
    final day = plan == null || dayNumber == null
        ? null
        : dayByNumber(plan, dayNumber);
    final colors = context.colors;
    final text = context.textStyles;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SquareIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.plan),
              ),
            ),
            const SizedBox(height: 16),
            if (day != null) ...[
              HeroCard(
                badge: TagBadge(
                  label: 'Day ${day.dayNumber} · ${weekdayShort(day.weekday)}',
                  showSparkle: true,
                ),
                title: day.title,
                meta: dayMeta(day),
                watermark: dayWatermark(day),
              ),
              const SizedBox(height: 24),
              Text('EXERCISES', style: text.section),
              const SizedBox(height: 12),
              for (final planExercise in day.exercises)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExerciseRow(planExercise: planExercise),
                ),
            ] else if (planState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Text(
                'This workout is no longer in your plan.',
                style: text.body.copyWith(color: colors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
