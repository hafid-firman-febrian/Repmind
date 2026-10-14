import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../application/services/plan_formatting.dart';
import '../../domain/models/plan_exercise_model.dart';

class ExerciseRow extends StatelessWidget {
  const ExerciseRow({super.key, required this.planExercise});

  final PlanExercise planExercise;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RepmindRadius.listTile),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: BorderRadius.circular(RepmindRadius.badge),
            ),
            child: Text('${planExercise.position}', style: text.section),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planExercise.exercise.name, style: text.subtitle),
                const SizedBox(height: 2),
                Text(
                  exerciseDetail(planExercise.exercise),
                  style: text.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(exerciseDose(planExercise), style: text.subtitle),
              const SizedBox(height: 2),
              Text(
                restLabel(planExercise),
                style: text.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
