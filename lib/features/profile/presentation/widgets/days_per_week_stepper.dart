import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../../application/services/profile_rules.dart';

class DaysPerWeekStepper extends StatelessWidget {
  const DaysPerWeekStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;

    return Row(
      children: [
        SquareIconButton(
          icon: Icons.remove_rounded,
          tooltip: 'Fewer days',
          onPressed: value > ProfileRules.minDaysPerWeek
              ? () => onChanged(value - 1)
              : null,
        ),
        Expanded(
          child: Column(
            children: [
              Text('$value', style: text.display),
              Text(
                'days per week',
                style: text.bodySmall.copyWith(color: context.colors.muted),
              ),
            ],
          ),
        ),
        SquareIconButton(
          icon: Icons.add_rounded,
          tooltip: 'More days',
          onPressed: value < ProfileRules.maxDaysPerWeek
              ? () => onChanged(value + 1)
              : null,
        ),
      ],
    );
  }
}
