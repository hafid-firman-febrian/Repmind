import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/option_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/repmind_text_field.dart';
import '../../application/services/adjust_rules.dart';

Future<String?> showAdjustPlanSheet(
  BuildContext context, {
  required int currentVersion,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AdjustPlanSheet(currentVersion: currentVersion),
);

class AdjustPlanSheet extends StatefulWidget {
  const AdjustPlanSheet({super.key, required this.currentVersion});

  final int currentVersion;

  @override
  State<AdjustPlanSheet> createState() => _AdjustPlanSheetState();
}

class _AdjustPlanSheetState extends State<AdjustPlanSheet> {
  final _instruction = TextEditingController();

  @override
  void initState() {
    super.initState();
    _instruction.addListener(_onChanged);
  }

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _useSuggestion(String suggestion) {
    _instruction.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
  }

  void _submit() => Navigator.of(context).pop(_instruction.text.trim());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final canSubmit =
        AdjustRules.validateInstruction(_instruction.text) == null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: colors.violet),
              const SizedBox(width: 8),
              Text('ADJUST YOUR PLAN', style: text.title),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tell the AI what to change. Your current plan is kept as v${widget.currentVersion}.',
            style: text.body.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in AdjustRules.suggestions)
                OptionChip(
                  label: suggestion,
                  selected: false,
                  onTap: () => _useSuggestion(suggestion),
                ),
            ],
          ),
          const SizedBox(height: 16),
          RepmindTextField(
            label: 'Instruction',
            controller: _instruction,
            hintText: 'e.g. More core work, keep sessions under 40 min',
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 5,
            maxLength: AdjustRules.maxLength,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Generate v${widget.currentVersion + 1}',
            variant: PrimaryButtonVariant.ai,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
