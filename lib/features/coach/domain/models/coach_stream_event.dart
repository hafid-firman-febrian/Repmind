import 'plan_proposal_model.dart';

sealed class CoachStreamEvent {
  const CoachStreamEvent();
}

final class CoachStarted extends CoachStreamEvent {
  const CoachStarted({required this.userMessageId});

  final String userMessageId;
}

final class CoachDelta extends CoachStreamEvent {
  const CoachDelta({required this.text});

  final String text;
}

final class CoachDone extends CoachStreamEvent {
  const CoachDone({
    required this.messageId,
    required this.proposal,
    required this.userConfirmed,
  });

  final String messageId;
  final PlanProposal? proposal;
  final bool userConfirmed;
}
