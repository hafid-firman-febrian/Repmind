import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/primary_button.dart';
import 'start_plan_generation.dart';

class GeneratePlanCard extends ConsumerWidget {
  const GeneratePlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.textStyles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(RepmindRadius.card),
        border: Border.all(color: colors.violetLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.violet,
              borderRadius: BorderRadius.circular(RepmindRadius.button),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: colors.onViolet,
            ),
          ),
          const SizedBox(height: 14),
          Text('YOUR AI PLAN', style: text.title),
          const SizedBox(height: 6),
          Text(
            'Gemini builds a weekly plan from your goal, level and equipment.',
            style: text.body.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Generate my plan',
            variant: PrimaryButtonVariant.ai,
            onPressed: () => startPlanGeneration(context, ref),
          ),
        ],
      ),
    );
  }
}
