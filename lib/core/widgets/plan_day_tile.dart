import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class PlanDayTile extends StatelessWidget {
  const PlanDayTile({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isToday,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String trailing;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.listTile),
      side: isToday
          ? BorderSide(color: colors.limeInk, width: 1.5)
          : BorderSide(color: colors.line),
    );

    return Material(
      color: colors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? colors.lime : colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(RepmindRadius.badge),
                  border: isToday ? Border.all(color: colors.limeEdge) : null,
                ),
                child: Text(badge, style: text.section),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.subtitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isToday)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.lime,
                    borderRadius: BorderRadius.circular(RepmindRadius.badge),
                    border: Border.all(color: colors.limeEdge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text('TODAY', style: text.label),
                  ),
                )
              else
                Text(
                  trailing,
                  style: text.bodySmall.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
