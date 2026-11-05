import 'package:repmind/features/coach/domain/models/chat_message_model.dart';
import 'package:repmind/features/coach/domain/models/plan_proposal_model.dart';

Map<String, dynamic> proposalRow({
  String basedOnPlanId = 'plan-1',
  int dayNumber = 2,
  String summary = 'Swap Dumbbell Shoulder Press for Dumbbell Lateral Raise',
  List<Map<String, dynamic>>? changes,
}) => {
  'based_on_plan_id': basedOnPlanId,
  'ai_model': 'gemini_flash_lite',
  'day_number': dayNumber,
  'summary': summary,
  'changes':
      changes ??
      [
        {
          'from_exercise_id': 'dumbbell_shoulder_press',
          'to_exercise_id': 'dumbbell_lateral_raise',
          'to_exercise_name': 'Dumbbell Lateral Raise',
          'sets': 3,
          'reps': '12',
          'rest_seconds': 60,
        },
      ],
};

Map<String, dynamic> chatMessageRow({
  String id = 'msg-1',
  String role = 'user',
  String content = 'My shoulder feels tight today',
  Map<String, dynamic>? proposal,
  String? appliedPlanId,
  int? appliedPlanVersion,
  String createdAt = '2026-11-05T08:00:00+00:00',
}) => {
  'id': id,
  'user_id': 'user-1',
  'role': role,
  'content': content,
  'proposal': proposal,
  'applied_plan_id': appliedPlanId,
  'created_at': createdAt,
  'applied_plan': appliedPlanVersion == null
      ? null
      : {'version': appliedPlanVersion},
};

PlanProposal sampleProposal({
  String basedOnPlanId = 'plan-1',
  int dayNumber = 2,
}) => PlanProposal.fromJson(
  proposalRow(basedOnPlanId: basedOnPlanId, dayNumber: dayNumber),
);

ChatMessage sampleCoachMessage({
  String id = 'msg-2',
  String role = 'assistant',
  String content = "Here's the change I suggest.",
  bool withProposal = false,
  String? appliedPlanId,
  int? appliedPlanVersion,
}) => ChatMessage.fromJson(
  chatMessageRow(
    id: id,
    role: role,
    content: content,
    proposal: withProposal ? proposalRow() : null,
    appliedPlanId: appliedPlanId,
    appliedPlanVersion: appliedPlanVersion,
  ),
);
