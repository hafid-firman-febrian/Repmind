import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/application/services/chat_context.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';

import '../../../fixtures/plan_fixtures.dart';

void main() {
  test('names the plan version and the goal', () {
    expect(
      chatContextLabel(samplePlan(version: 2), FitnessGoal.buildMuscle),
      'Using plan v2 · Build muscle',
    );
  });

  test('says there is no plan yet', () {
    expect(
      chatContextLabel(null, FitnessGoal.buildMuscle),
      'No plan yet · Build muscle',
    );
  });
}
