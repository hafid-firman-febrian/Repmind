import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_message.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../plan/domain/models/plan_day_model.dart';
import '../../application/services/proposal_preview.dart';
import '../../domain/models/chat_message_model.dart';
import '../controllers/coach_chat_controller.dart';

Future<void> showReviewChangeSheet(
  BuildContext context, {
  required ChatMessage message,
  required PlanDay day,
  required int nextVersion,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  enableDrag: false,
  builder: (_) =>
      ReviewChangeSheet(message: message, day: day, nextVersion: nextVersion),
);

class ReviewChangeSheet extends ConsumerStatefulWidget {
  const ReviewChangeSheet({
    super.key,
    required this.message,
    required this.day,
    required this.nextVersion,
  });

  final ChatMessage message;
  final PlanDay day;
  final int nextVersion;

  @override
  ConsumerState<ReviewChangeSheet> createState() => _ReviewChangeSheetState();
}

class _ReviewChangeSheetState extends ConsumerState<ReviewChangeSheet> {
  var _applying = false;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await ref
          .read(coachChatControllerProvider.notifier)
          .applyProposal(widget.message.id);
      if (!mounted) return;
      setState(() => _applying = false);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, messageOf(error));
      setState(() => _applying = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final proposal = widget.message.proposal;
    final rows = proposal == null
        ? const <PreviewRow>[]
        : previewDayChange(widget.day, proposal);

    return PopScope(
      canPop: !_applying,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: colors.violet,
                ),
                const SizedBox(width: 6),
                Text(
                  'REVIEW CHANGE',
                  style: text.label.copyWith(color: colors.violet),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.day.title.toUpperCase(), style: text.title),
            const SizedBox(height: 8),
            for (final row in rows) _PreviewRowTile(row: row),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Apply as v${widget.nextVersion}',
              variant: PrimaryButtonVariant.ai,
              isLoading: _applying,
              onPressed: _apply,
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: 'Cancel',
              onPressed: _applying ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRowTile extends StatelessWidget {
  const _PreviewRowTile({required this.row});

  final PreviewRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    final (nameStyle, doseStyle) = switch (row.kind) {
      PreviewRowKind.unchanged => (
        text.body,
        text.body.copyWith(color: colors.muted),
      ),
      PreviewRowKind.removed => (
        text.body.copyWith(
          color: colors.muted,
          decoration: TextDecoration.lineThrough,
        ),
        text.body.copyWith(
          color: colors.muted,
          decoration: TextDecoration.lineThrough,
        ),
      ),
      PreviewRowKind.added => (
        text.body.copyWith(fontWeight: FontWeight.w700),
        text.body.copyWith(color: colors.violet, fontWeight: FontWeight.w700),
      ),
    };

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(row.name, style: nameStyle)),
        const SizedBox(width: 8),
        Text(row.dose, style: doseStyle),
      ],
    );

    if (row.kind == PreviewRowKind.added) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.violetTint,
            borderRadius: BorderRadius.circular(RepmindRadius.badge),
            border: Border.all(color: colors.violetLine),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: content,
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: content,
      ),
    );
  }
}
