import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/models/workout_plan_model.dart';
import '../controllers/active_plan_controller.dart';
import 'generate_plan_card.dart';

class ActivePlanSection extends ConsumerWidget {
  const ActivePlanSection({super.key, required this.builder});

  final Widget Function(BuildContext context, WorkoutPlan plan) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activePlanControllerProvider);
    final plan = state.value;
    if (plan != null) return builder(context, plan);
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final error = state.error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              messageOf(error),
              textAlign: TextAlign.center,
              style: context.textStyles.body.copyWith(
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Try again',
              onPressed: () => ref.invalidate(activePlanControllerProvider),
            ),
          ],
        ),
      );
    }
    return const GeneratePlanCard();
  }
}
