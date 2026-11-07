import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/application/services/proposal_preview.dart';
import 'package:repmind/features/coach/domain/models/plan_proposal_model.dart';
import 'package:repmind/features/plan/domain/models/plan_day_model.dart';

import '../../../fixtures/plan_fixtures.dart';

PlanDay pushDay() => samplePlan().days[1];

PlanChange change(
  String from,
  String to,
  String toName, {
  int sets = 3,
  String reps = '12',
}) => PlanChange(
  fromExerciseId: from,
  toExerciseId: to,
  toExerciseName: toName,
  sets: sets,
  reps: reps,
  restSeconds: 60,
);

PlanProposal proposal(List<PlanChange> changes) => PlanProposal(
  basedOnPlanId: 'plan-1',
  dayNumber: 2,
  summary: 'summary',
  changes: changes,
);

void main() {
  test('marks a swap as a removed row followed by an added row', () {
    final rows = previewDayChange(
      pushDay(),
      proposal([
        change('dumbbell_shoulder_press', 'face_pull', 'Face Pull', reps: '15'),
      ]),
    );

    expect(rows.map((row) => row.name).toList(), [
      'Dumbbell Bench Press',
      'Dumbbell Shoulder Press',
      'Face Pull',
      'Push-up',
      'Dumbbell Lateral Raise',
      'Overhead Triceps Extension',
      'Diamond Push-up',
    ]);
    expect(rows.map((row) => row.kind).toList(), [
      PreviewRowKind.unchanged,
      PreviewRowKind.removed,
      PreviewRowKind.added,
      PreviewRowKind.unchanged,
      PreviewRowKind.unchanged,
      PreviewRowKind.unchanged,
      PreviewRowKind.unchanged,
    ]);
  });

  test('formats doses like exerciseDose for existing and added rows', () {
    final rows = previewDayChange(
      pushDay(),
      proposal([
        change(
          'dumbbell_shoulder_press',
          'face_pull',
          'Face Pull',
          sets: 4,
          reps: '8-10',
        ),
      ]),
    );

    expect(rows[0].dose, '4 × 8–10');
    expect(rows[1].dose, '3 × 10');
    expect(rows[2].dose, '4 × 8–10');
    expect(rows[3].dose, '3 × 12');
  });

  test('shows a sets change on the same exercise as two rows', () {
    final rows = previewDayChange(
      pushDay(),
      proposal([change('push_up', 'push_up', 'Push-up', sets: 4)]),
    );

    final pushUps = rows.where((row) => row.name == 'Push-up').toList();
    expect(pushUps.map((row) => row.kind).toList(), [
      PreviewRowKind.removed,
      PreviewRowKind.added,
    ]);
    expect(pushUps.map((row) => row.dose).toList(), ['3 × 12', '4 × 12']);
    expect(rows, hasLength(7));
  });

  test('keeps every row unchanged when there are no changes', () {
    final rows = previewDayChange(pushDay(), proposal([]));

    expect(rows, hasLength(6));
    expect(rows.every((row) => row.kind == PreviewRowKind.unchanged), isTrue);
  });
}
