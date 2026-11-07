import '../../../plan/domain/models/workout_plan_model.dart';
import '../../domain/models/chat_message_model.dart';

enum ProposalStatus { pending, applied, outdated }

ProposalStatus proposalStatusOf(ChatMessage message, WorkoutPlan? activePlan) {
  if (message.appliedPlanId != null) return ProposalStatus.applied;
  if (activePlan != null && message.proposal?.basedOnPlanId == activePlan.id) {
    return ProposalStatus.pending;
  }
  return ProposalStatus.outdated;
}
