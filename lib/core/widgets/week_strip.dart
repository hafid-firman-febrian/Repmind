import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

enum WeekStripStatus { scheduled, rest }

class WeekStripItem {
  const WeekStripItem({
    required this.dayName,
    required this.status,
    required this.isToday,
  });

  final String dayName;
  final WeekStripStatus status;
  final bool isToday;
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.items});

  final List<WeekStripItem> items;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final item in items) Expanded(child: _WeekStripDay(item: item)),
    ],
  );
}

class _WeekStripDay extends StatelessWidget {
  const _WeekStripDay({required this.item});

  final WeekStripItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final scheduled = item.status == WeekStripStatus.scheduled;
    final label = [
      item.dayName,
      scheduled ? 'workout' : 'rest',
      if (item.isToday) 'today',
    ].join(', ');

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            item.dayName.substring(0, 1),
            style: text.bodySmall.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 6),
          Container(
            key: ValueKey('week-strip-mark-${item.dayName}'),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheduled ? colors.surfaceSunken : null,
              borderRadius: BorderRadius.circular(RepmindRadius.badge),
              border: item.isToday
                  ? Border.all(color: colors.limeInk, width: 1.5)
                  : null,
            ),
            child: scheduled
                ? null
                : Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.chartMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
