import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';

class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.limeEdge,
        borderRadius: BorderRadius.circular(RepmindRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: context.textStyles.bodySmall.copyWith(color: colors.onLime),
        ),
      ),
    );
  }
}
