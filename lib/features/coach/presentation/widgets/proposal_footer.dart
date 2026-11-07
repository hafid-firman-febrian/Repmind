import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../plan/domain/models/workout_plan_model.dart';
import '../../../plan/presentation/controllers/active_plan_controller.dart';
import '../../../plan/presentation/widgets/active_plan_section.dart';
import '../../application/services/proposal_status.dart';
import '../../domain/models/chat_message_model.dart';
import 'review_change_sheet.dart';

ProposalStatus proposalStatusInPlan(ChatMessage message, WorkoutPlan? plan) {
  final status = proposalStatusOf(message, plan);
  final proposal = message.proposal;
  if (status != ProposalStatus.pending || proposal == null || plan == null) {
    return status;
  }
  final hasDay = plan.days.any((day) => day.dayNumber == proposal.dayNumber);
  return hasDay ? status : ProposalStatus.outdated;
}

Future<void> openReviewChange(
  BuildContext context,
  WidgetRef ref,
  ChatMessage message,
) async {
  final proposal = message.proposal;
  final plan = currentPlanOf(ref.read(activePlanControllerProvider));
  if (proposal == null || plan == null) return;
  if (proposalStatusInPlan(message, plan) != ProposalStatus.pending) return;
  final day = plan.days.firstWhere(
    (day) => day.dayNumber == proposal.dayNumber,
  );
  await showReviewChangeSheet(
    context,
    message: message,
    day: day,
    nextVersion: plan.version + 1,
  );
}

class ProposalFooter extends ConsumerWidget {
  const ProposalFooter({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposal = message.proposal;
    if (proposal == null) return const SizedBox.shrink();
    final planState = ref.watch(activePlanControllerProvider);
    final plan = currentPlanOf(planState);
    final status = proposalStatusInPlan(message, plan);
    final planKnown = planState.hasValue && !planState.hasError;
    if (!planKnown && status != ProposalStatus.applied) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final text = context.textStyles;

    return switch (status) {
      ProposalStatus.pending => Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => openReviewChange(context, ref, message),
          style: FilledButton.styleFrom(
            backgroundColor: colors.violet,
            foregroundColor: colors.onViolet,
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RepmindRadius.button),
            ),
            textStyle: text.body.copyWith(fontWeight: FontWeight.w700),
          ),
          child: const Text('Review change'),
        ),
      ),
      ProposalStatus.applied => Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.lime,
              borderRadius: BorderRadius.circular(RepmindRadius.badge),
              border: Border.all(color: colors.limeEdge),
            ),
            child: SizedBox.square(
              dimension: 20,
              child: Icon(Icons.check_rounded, size: 14, color: colors.onLime),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.appliedPlanVersion == null
                  ? 'Plan updated'
                  : 'Plan updated to v${message.appliedPlanVersion}',
              style: text.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () =>
                context.push(AppRoutes.workoutDayPath(proposal.dayNumber)),
            style: TextButton.styleFrom(
              foregroundColor: colors.violet,
              textStyle: text.body.copyWith(fontWeight: FontWeight.w700),
              minimumSize: const Size(48, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('View plan'),
          ),
        ],
      ),
      ProposalStatus.outdated => Text(
        'Your plan has changed since this suggestion.',
        style: text.bodySmall.copyWith(color: colors.muted),
      ),
    };
  }
}
