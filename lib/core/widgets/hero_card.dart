import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    this.badge,
    this.meta,
    this.watermark,
    this.footer,
  });

  final String title;
  final Widget? badge;
  final String? meta;
  final String? watermark;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final badge = this.badge;
    final meta = this.meta;
    final watermark = this.watermark;
    final footer = this.footer;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.lime,
        borderRadius: BorderRadius.circular(RepmindRadius.hero),
        border: Border.all(color: colors.limeEdge),
      ),
      child: Stack(
        children: [
          if (watermark != null)
            Positioned(
              right: -4,
              top: -20,
              child: Text(
                watermark,
                style: text.watermark.copyWith(
                  color: colors.onLime.withValues(alpha: 0.12),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[badge, const SizedBox(height: 10)],
                  Text(
                    title.toUpperCase(),
                    style: text.headline.copyWith(color: colors.onLime),
                  ),
                  if (meta != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      style: text.bodySmall.copyWith(
                        color: colors.onLime.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (footer != null) ...[const SizedBox(height: 14), footer],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
