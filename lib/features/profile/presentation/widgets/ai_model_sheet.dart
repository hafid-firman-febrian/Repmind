import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/selectable_card.dart';
import '../../domain/models/ai_model.dart';

Future<AiModel?> showAiModelSheet(
  BuildContext context, {
  required AiModel current,
}) => showModalBottomSheet<AiModel>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => AiModelSheet(current: current),
);

class AiModelSheet extends StatelessWidget {
  const AiModelSheet({super.key, required this.current});

  final AiModel current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('AI MODEL', style: text.title),
          const SizedBox(height: 6),
          Text(
            'Used the next time you generate or adjust a plan.',
            style: text.body.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 16),
          for (final model in AiModel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SelectableCard(
                title: model.label,
                subtitle: model.description,
                selected: model == current,
                onTap: () => Navigator.of(context).pop(model),
              ),
            ),
        ],
      ),
    );
  }
}
