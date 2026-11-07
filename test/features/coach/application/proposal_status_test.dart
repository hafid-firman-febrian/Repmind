import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/application/services/proposal_status.dart';

import '../../../fixtures/coach_fixtures.dart';
import '../../../fixtures/plan_fixtures.dart';

void main() {
  test('is applied when the message carries an applied plan id', () {
    final message = sampleCoachMessage(
      withProposal: true,
      appliedPlanId: 'plan-2',
      appliedPlanVersion: 2,
    );

    expect(
      proposalStatusOf(message, samplePlan(version: 3)),
      ProposalStatus.applied,
    );
    expect(proposalStatusOf(message, null), ProposalStatus.applied);
  });

  test('is pending while the active plan is the one it was based on', () {
    final message = sampleCoachMessage(withProposal: true);

    expect(
      proposalStatusOf(message, samplePlan(version: 1)),
      ProposalStatus.pending,
    );
  });

  test('is outdated when the active plan changed or is missing', () {
    final message = sampleCoachMessage(withProposal: true);

    expect(
      proposalStatusOf(message, samplePlan(version: 2)),
      ProposalStatus.outdated,
    );
    expect(proposalStatusOf(message, null), ProposalStatus.outdated);
  });
}
