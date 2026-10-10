import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final background = highlighted ? colors.orange : colors.surface;
    final foreground = highlighted ? colors.onOrange : colors.ink;
    final secondary = highlighted
        ? colors.onOrange.withValues(alpha: 0.72)
        : colors.muted;

    return Container(
      height: 84,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RepmindRadius.card),
        border: Border.all(color: highlighted ? background : colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.stat.copyWith(color: foreground),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall.copyWith(color: secondary),
          ),
        ],
      ),
    );
  }
}
