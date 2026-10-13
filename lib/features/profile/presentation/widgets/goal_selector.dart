import 'package:flutter/material.dart';

import '../../../../core/widgets/selectable_card.dart';
import '../../domain/models/fitness_goal.dart';
import '../states/profile_draft.dart';

class GoalSelector extends StatelessWidget {
  const GoalSelector({super.key, required this.draft, required this.onChanged});

  final ProfileDraft draft;
  final ValueChanged<ProfileDraft> onChanged;

  static IconData _iconFor(FitnessGoal goal) => switch (goal) {
    FitnessGoal.loseWeight => Icons.local_fire_department_rounded,
    FitnessGoal.buildMuscle => Icons.fitness_center_rounded,
    FitnessGoal.stayFit => Icons.directions_run_rounded,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final goal in FitnessGoal.values) ...[
        SelectableCard(
          title: goal.label,
          subtitle: goal.description,
          icon: _iconFor(goal),
          selected: draft.goal == goal,
          onTap: () => onChanged(draft.copyWith(goal: goal)),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}
