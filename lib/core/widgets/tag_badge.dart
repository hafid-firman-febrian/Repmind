import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

enum TagTone { onColor, onSurface }

class TagBadge extends StatelessWidget {
  const TagBadge({
    super.key,
    required this.label,
    this.showSparkle = false,
    this.tone = TagTone.onColor,
  });

  final String label;
  final bool showSparkle;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = switch (tone) {
      TagTone.onColor => colors.surface,
      TagTone.onSurface => colors.surfaceSunken,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RepmindRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSparkle) ...[
              Icon(Icons.auto_awesome_rounded, size: 12, color: colors.violet),
              const SizedBox(width: 5),
            ],
            Text(label.toUpperCase(), style: context.textStyles.label),
          ],
        ),
      ),
    );
  }
}
