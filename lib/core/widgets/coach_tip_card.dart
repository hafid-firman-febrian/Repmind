import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class CoachTipCard extends StatelessWidget {
  const CoachTipCard({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.card),
    );

    return Semantics(
      button: true,
      label: 'Coach tip. $text',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: colors.violet,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: colors.onViolet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach tip',
                          style: styles.subtitle.copyWith(
                            color: colors.onViolet,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: styles.body.copyWith(color: colors.onViolet),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onViolet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
