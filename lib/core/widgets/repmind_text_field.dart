import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class RepmindTextField extends StatelessWidget {
  const RepmindTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autofillHints,
    this.suffixText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final String? suffixText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: text.label.copyWith(color: colors.muted),
          ),
        ),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autofillHints: autofillHints,
          enabled: enabled,
          style: text.body,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}
