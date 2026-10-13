import 'package:flutter/material.dart';

import '../theme/repmind_radius.dart';
import '../theme/theme_context.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = destructive ? colors.danger : colors.ink;
    final icon = this.icon;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: foreground,
          side: BorderSide(color: colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RepmindRadius.button),
          ),
          textStyle: context.textStyles.subtitle,
        ),
        child: isLoading
            ? SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
