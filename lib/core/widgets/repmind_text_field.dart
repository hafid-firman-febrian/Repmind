import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class RepmindTextField extends StatefulWidget {
  const RepmindTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
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
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final String? suffixText;
  final bool enabled;

  @override
  State<RepmindTextField> createState() => _RepmindTextFieldState();
}

class _RepmindTextFieldState extends State<RepmindTextField> {
  late bool _obscured = widget.obscureText;

  @override
  void didUpdateWidget(RepmindTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

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
            widget.label.toUpperCase(),
            style: text.label.copyWith(color: colors.muted),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscured,
          autofillHints: widget.autofillHints,
          enabled: widget.enabled,
          style: text.body,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
            suffixText: widget.suffixText,
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.muted,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
