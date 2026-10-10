import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RepmindRadius.button),
      side: BorderSide(color: colors.line),
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? colors.ink : colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
