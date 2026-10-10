import 'package:flutter/material.dart';

import '../../../../core/widgets/repmind_text_field.dart';
import '../states/profile_draft.dart';

class BodyMetricsFields extends StatelessWidget {
  const BodyMetricsFields({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ProfileDraft draft;
  final ValueChanged<ProfileDraft> onChanged;

  static String? _visibleError(String text, String? error) =>
      text.isEmpty ? null : error;

  @override
  Widget build(BuildContext context) {
    const decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Column(
      children: [
        RepmindTextField(
          key: const ValueKey('weight-field'),
          label: 'Weight',
          initialValue: draft.weightText,
          hintText: 'e.g. 72.5',
          suffixText: 'kg',
          keyboardType: decimalKeyboard,
          errorText: _visibleError(draft.weightText, draft.weightError),
          onChanged: (value) => onChanged(draft.copyWith(weightText: value)),
        ),
        const SizedBox(height: 16),
        RepmindTextField(
          key: const ValueKey('height-field'),
          label: 'Height',
          initialValue: draft.heightText,
          hintText: 'e.g. 175',
          suffixText: 'cm',
          keyboardType: decimalKeyboard,
          errorText: _visibleError(draft.heightText, draft.heightError),
          onChanged: (value) => onChanged(draft.copyWith(heightText: value)),
        ),
      ],
    );
  }
}
