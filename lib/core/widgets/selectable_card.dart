import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final secondary = selected
        ? colors.onLime.withValues(alpha: 0.7)
        : colors.muted;
    final subtitle = this.subtitle;
    final icon = this.icon;
    final radius = BorderRadius.circular(RepmindRadius.card);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.lime : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide(color: colors.limeInk, width: 1.5)
              : BorderSide(color: colors.line),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.ink),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.subtitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: text.bodySmall.copyWith(color: secondary),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? colors.limeInk : colors.line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
