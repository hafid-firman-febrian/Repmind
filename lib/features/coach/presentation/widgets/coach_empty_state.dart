import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../application/services/coach_rules.dart';

class CoachEmptyState extends StatelessWidget {
  const CoachEmptyState({super.key, required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask me about your training', style: text.subtitle),
        const SizedBox(height: 4),
        Text(
          "I know your goal, your equipment, and this week's plan.",
          style: text.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 12),
        for (final suggestion in CoachRules.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Suggestion(
              label: suggestion,
              onTap: () => onSuggestion(suggestion),
            ),
          ),
      ],
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.listTile),
      side: BorderSide(color: colors.violetLine),
    );

    return Material(
      color: colors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              label,
              style: context.textStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
