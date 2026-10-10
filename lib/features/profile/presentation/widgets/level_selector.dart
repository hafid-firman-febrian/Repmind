import 'package:flutter/material.dart';

import '../../../../core/widgets/selectable_card.dart';
import '../../domain/models/fitness_level.dart';
import '../states/profile_draft.dart';

class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ProfileDraft draft;
  final ValueChanged<ProfileDraft> onChanged;

  static IconData _iconFor(FitnessLevel level) => switch (level) {
    FitnessLevel.beginner => Icons.signal_cellular_alt_1_bar_rounded,
    FitnessLevel.intermediate => Icons.signal_cellular_alt_2_bar_rounded,
    FitnessLevel.advanced => Icons.signal_cellular_alt_rounded,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final level in FitnessLevel.values) ...[
        SelectableCard(
          title: level.label,
          subtitle: level.description,
          icon: _iconFor(level),
          selected: draft.level == level,
          onTap: () => onChanged(draft.copyWith(level: level)),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );
}
