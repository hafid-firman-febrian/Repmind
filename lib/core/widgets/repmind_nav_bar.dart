import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

enum NavTone { lime, violet, orange }

class RepmindNavItem {
  const RepmindNavItem({
    required this.icon,
    required this.label,
    required this.tone,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final NavTone tone;
  final bool enabled;
}

class RepmindNavBar extends StatelessWidget {
  const RepmindNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<RepmindNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(RepmindRadius.navBar);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.08),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.92),
                borderRadius: radius,
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var index = 0; index < items.length; index++)
                      _NavTab(
                        item: items[index],
                        selected: index == currentIndex,
                        onTap: items[index].enabled
                            ? () => onSelected(index)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final RepmindNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fill, iconColor) = !selected
        ? (null, colors.muted)
        : switch (item.tone) {
            NavTone.lime => (colors.lime, colors.onLime),
            NavTone.violet => (colors.violet, colors.onViolet),
            NavTone.orange => (colors.orange, colors.onOrange),
          };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.navTab),
      side: selected && item.tone == NavTone.lime
          ? BorderSide(color: colors.limeEdge)
          : BorderSide.none,
    );

    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        label: item.label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          type: fill == null ? MaterialType.transparency : MaterialType.canvas,
          color: fill,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(item.icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
