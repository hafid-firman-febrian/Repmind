import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

class AuthFormError extends StatelessWidget {
  const AuthFormError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: context.textStyles.bodySmall.copyWith(
          color: context.colors.danger,
        ),
      ),
    );
  }
}
