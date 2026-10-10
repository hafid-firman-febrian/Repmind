import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/option_chip.dart';
import '../../domain/models/equipment.dart';
import '../states/profile_draft.dart';
import 'days_per_week_stepper.dart';

class ScheduleEquipmentFields extends StatelessWidget {
  const ScheduleEquipmentFields({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ProfileDraft draft;
  final ValueChanged<ProfileDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DaysPerWeekStepper(
          value: draft.daysPerWeek,
          onChanged: (days) => onChanged(draft.withDaysPerWeek(days)),
        ),
        const SizedBox(height: 28),
        Text('EQUIPMENT', style: text.label.copyWith(color: colors.muted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in Equipment.values)
              OptionChip(
                label: item.label,
                selected: draft.equipment.contains(item),
                onTap: () => onChanged(draft.toggleEquipment(item)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Bodyweight exercises are always included.',
          style: text.bodySmall.copyWith(color: colors.muted),
        ),
      ],
    );
  }
}
