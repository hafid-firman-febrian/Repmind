import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.badge),
      side: BorderSide(color: selected ? colors.limeEdge : colors.line),
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.lime : colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(label, style: context.textStyles.body),
          ),
        ),
      ),
    );
  }
}
