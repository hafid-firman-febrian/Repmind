import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/domain/models/chat_message_model.dart';

import '../../../fixtures/coach_fixtures.dart';

void main() {
  test('parses a user message', () {
    final message = ChatMessage.fromJson(chatMessageRow());

    expect(message.id, 'msg-1');
    expect(message.role, ChatRole.user);
    expect(message.content, 'My shoulder feels tight today');
    expect(message.proposal, isNull);
    expect(message.appliedPlanId, isNull);
    expect(message.appliedPlanVersion, isNull);
    expect(message.createdAt, DateTime.parse('2026-11-05T08:00:00+00:00'));
  });

  test('parses an assistant message with a proposal', () {
    final message = ChatMessage.fromJson(
      chatMessageRow(role: 'assistant', proposal: proposalRow()),
    );

    expect(message.role, ChatRole.assistant);
    final proposal = message.proposal!;
    expect(proposal.basedOnPlanId, 'plan-1');
    expect(proposal.dayNumber, 2);
    expect(
      proposal.summary,
      'Swap Dumbbell Shoulder Press for Dumbbell Lateral Raise',
    );
    expect(proposal.changes, hasLength(1));
    final change = proposal.changes.single;
    expect(change.fromExerciseId, 'dumbbell_shoulder_press');
    expect(change.toExerciseId, 'dumbbell_lateral_raise');
    expect(change.toExerciseName, 'Dumbbell Lateral Raise');
    expect(change.sets, 3);
    expect(change.reps, '12');
    expect(change.restSeconds, 60);
  });

  test('reads the applied plan version from the nested row', () {
    final message = ChatMessage.fromJson(
      chatMessageRow(
        role: 'assistant',
        proposal: proposalRow(),
        appliedPlanId: 'plan-2',
        appliedPlanVersion: 2,
      ),
    );

    expect(message.appliedPlanId, 'plan-2');
    expect(message.appliedPlanVersion, 2);
  });

  test('a null applied plan leaves the version empty', () {
    final message = ChatMessage.fromJson(
      chatMessageRow(role: 'assistant', proposal: proposalRow()),
    );

    expect(message.appliedPlanId, isNull);
    expect(message.appliedPlanVersion, isNull);
  });

  test('copyWith replaces only the id and applied plan fields', () {
    final original = sampleCoachMessage(withProposal: true);
    final copy = original.copyWith(
      id: 'msg-9',
      appliedPlanId: 'plan-3',
      appliedPlanVersion: 3,
    );

    expect(copy.id, 'msg-9');
    expect(copy.appliedPlanId, 'plan-3');
    expect(copy.appliedPlanVersion, 3);
    expect(copy.role, original.role);
    expect(copy.content, original.content);
    expect(copy.proposal, same(original.proposal));
    expect(copy.createdAt, original.createdAt);
    expect(original.id, 'msg-2');
  });

  test('ChatRole maps database values', () {
    expect(ChatRole.fromDb('user'), ChatRole.user);
    expect(ChatRole.fromDb('assistant'), ChatRole.assistant);
    expect(ChatRole.assistant.dbValue, 'assistant');
  });
}
