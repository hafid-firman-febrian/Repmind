import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../../../profile/presentation/widgets/body_metrics_fields.dart';
import '../../../profile/presentation/widgets/goal_selector.dart';
import '../../../profile/presentation/widgets/level_selector.dart';
import '../../../profile/presentation/widgets/schedule_equipment_fields.dart';
import '../controllers/onboarding_controller.dart';
import '../states/onboarding_state.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  static (String, String) _copyFor(OnboardingStep step) => switch (step) {
    OnboardingStep.goal => (
      "What's your main goal?",
      "We'll shape your plan around it.",
    ),
    OnboardingStep.level => (
      'How experienced are you?',
      'Be honest. Your coach adjusts as you go.',
    ),
    OnboardingStep.schedule => (
      'How often can you train?',
      'Pick your days per week and the equipment you have.',
    ),
    OnboardingStep.body => (
      'A bit about you',
      'Used to tailor your volume and track progress.',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(onboardingControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) return;
      showAppSnackBar(context, error.message);
    });

    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final colors = context.colors;
    final text = context.textStyles;
    final (title, subtitle) = _copyFor(state.step);

    final content = switch (state.step) {
      OnboardingStep.goal => GoalSelector(
        draft: state.draft,
        onChanged: controller.updateDraft,
      ),
      OnboardingStep.level => LevelSelector(
        draft: state.draft,
        onChanged: controller.updateDraft,
      ),
      OnboardingStep.schedule => ScheduleEquipmentFields(
        draft: state.draft,
        onChanged: controller.updateDraft,
      ),
      OnboardingStep.body => BodyMetricsFields(
        draft: state.draft,
        onChanged: controller.updateDraft,
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (state.isFirstStep)
                    const SizedBox.square(dimension: 40)
                  else
                    SquareIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onPressed: controller.back,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(RepmindRadius.badge),
                      color: colors.limeInk,
                      backgroundColor: colors.line,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Step ${state.step.index + 1} of ${OnboardingStep.values.length}',
                    style: text.bodySmall.copyWith(color: colors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(title.toUpperCase(), style: text.title),
              const SizedBox(height: 6),
              Text(subtitle, style: text.body.copyWith(color: colors.muted)),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: KeyedSubtree(
                    key: ValueKey(state.step),
                    child: content,
                  ),
                ),
              ),
              PrimaryButton(
                label: state.isLastStep ? 'Finish' : 'Next',
                isLoading: state.isSubmitting,
                onPressed: !state.canContinue
                    ? null
                    : state.isLastStep
                    ? controller.submit
                    : controller.next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
