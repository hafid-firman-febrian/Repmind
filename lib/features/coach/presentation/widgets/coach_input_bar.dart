import 'package:flutter/material.dart';

import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../application/services/coach_rules.dart';

class CoachInputBar extends StatelessWidget {
  const CoachInputBar({
    super.key,
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final enabled = canSend && CoachRules.canSend(value.text);
        void send() => onSend(controller.text);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: CoachRules.maxMessageLength,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: enabled ? (_) => send() : null,
                style: context.textStyles.body,
                decoration: const InputDecoration(
                  hintText: 'Ask your coach...',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Send',
              child: Material(
                color: enabled
                    ? colors.violet
                    : colors.violet.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(RepmindRadius.field),
                child: InkWell(
                  borderRadius: BorderRadius.circular(RepmindRadius.field),
                  onTap: enabled ? send : null,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
                      color: colors.onViolet,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
