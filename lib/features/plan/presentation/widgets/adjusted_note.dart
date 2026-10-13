import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';

class AdjustedNote extends StatelessWidget {
  const AdjustedNote({super.key, required this.instruction});

  final String instruction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.violetTint,
        borderRadius: BorderRadius.circular(RepmindRadius.card),
        border: Border.all(color: colors.violetLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: colors.violet),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Adjusted: “$instruction”',
              style: context.textStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
