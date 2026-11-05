import '../../../plan/application/services/plan_formatting.dart';
import '../../../plan/domain/models/plan_day_model.dart';
import '../../domain/models/plan_proposal_model.dart';

enum PreviewRowKind { unchanged, removed, added }

class PreviewRow {
  const PreviewRow({
    required this.name,
    required this.dose,
    required this.kind,
  });

  final String name;
  final String dose;
  final PreviewRowKind kind;
}

List<PreviewRow> previewDayChange(PlanDay day, PlanProposal proposal) {
  final changes = {
    for (final change in proposal.changes) change.fromExerciseId: change,
  };
  final rows = <PreviewRow>[];
  for (final planExercise in day.exercises) {
    final name = planExercise.exercise.name;
    final dose = exerciseDose(planExercise);
    final change = changes[planExercise.exercise.id];
    if (change == null) {
      rows.add(
        PreviewRow(name: name, dose: dose, kind: PreviewRowKind.unchanged),
      );
      continue;
    }
    rows.add(PreviewRow(name: name, dose: dose, kind: PreviewRowKind.removed));
    rows.add(
      PreviewRow(
        name: change.toExerciseName,
        dose: doseLabel(change.sets, change.reps),
        kind: PreviewRowKind.added,
      ),
    );
  }
  return rows;
}
