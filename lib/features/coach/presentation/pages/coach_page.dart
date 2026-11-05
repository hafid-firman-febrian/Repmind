import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_message.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../plan/presentation/controllers/active_plan_controller.dart';
import '../../../plan/presentation/widgets/active_plan_section.dart';
import '../../../plan/presentation/widgets/start_plan_generation.dart';
import '../../../profile/domain/models/ai_model.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/ai_model_sheet.dart';
import '../../application/services/chat_context.dart';
import '../../domain/models/chat_message_model.dart';
import '../controllers/coach_chat_controller.dart';
import '../states/coach_chat_state.dart';
import '../widgets/chat_context_chip.dart';
import '../widgets/coach_bubbles.dart';
import '../widgets/coach_empty_state.dart';
import '../widgets/coach_input_bar.dart';
import '../widgets/proposal_footer.dart';

class CoachPage extends ConsumerStatefulWidget {
  const CoachPage({super.key});

  @override
  ConsumerState<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends ConsumerState<CoachPage> {
  final _controller = TextEditingController();
  String? _autoReviewed;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String text) {
    ref.read(coachChatControllerProvider.notifier).send(text);
  }

  void _submit(String text) {
    _send(text);
    _controller.clear();
  }

  void _scheduleAutoReview(CoachChatState state) {
    final id = state.autoReviewMessageId;
    if (id == null || id == _autoReviewed) return;
    if (!TickerMode.valuesOf(context).enabled) return;
    _autoReviewed = id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifier = ref.read(coachChatControllerProvider.notifier);
      final messages =
          ref.read(coachChatControllerProvider).value?.messages ?? const [];
      final message = messages.where((message) => message.id == id).firstOrNull;
      notifier.clearAutoReview();
      if (message == null) return;
      await openReviewChange(context, ref, message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(coachChatControllerProvider);
    final planState = ref.watch(activePlanControllerProvider);
    final loaded = chat.value;
    if (loaded != null && planState.hasValue && !planState.hasError) {
      _scheduleAutoReview(loaded);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 12),
              Expanded(
                child: chat.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _LoadError(error: error),
                  data: (state) => _Conversation(
                    state: state,
                    controller: _controller,
                    onSuggestion: _send,
                    onSubmit: _submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.violet,
            borderRadius: BorderRadius.circular(RepmindRadius.button),
          ),
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 22,
              color: colors.onViolet,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('COACH', style: text.title),
              Text(
                'Knows your goal and plan',
                style: text.body.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          messageOf(error),
          textAlign: TextAlign.center,
          style: context.textStyles.body.copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Try again',
          onPressed: () => ref.invalidate(coachChatControllerProvider),
        ),
      ],
    ),
  );
}

class _Conversation extends ConsumerWidget {
  const _Conversation({
    required this.state,
    required this.controller,
    required this.onSuggestion,
    required this.onSubmit,
  });

  final CoachChatState state;
  final TextEditingController controller;
  final ValueChanged<String> onSuggestion;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(profileControllerProvider).value?.goal;
    final planState = ref.watch(activePlanControllerProvider);
    final planKnown = planState.hasValue && !planState.hasError;
    final plan = currentPlanOf(planState);
    final reply = state.reply;
    final streaming = reply is CoachReplyStreaming;
    final isEmpty = state.messages.isEmpty && reply is CoachReplyIdle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goal != null && planKnown) ...[
          ChatContextChip(label: chatContextLabel(plan, goal)),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: isEmpty
              ? CoachEmptyState(onSuggestion: onSuggestion)
              : _MessageList(
                  state: state,
                  offerPlan: planKnown && plan == null,
                ),
        ),
        const SizedBox(height: 12),
        CoachInputBar(
          controller: controller,
          canSend: !streaming,
          onSend: onSubmit,
        ),
      ],
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({required this.state, required this.offerPlan});

  final CoachChatState state;
  final bool offerPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reply = state.reply;
    final model = ref.watch(profileControllerProvider).value?.aiModel;
    final messages = state.messages;
    final last = messages.isEmpty ? null : messages.last;
    final items = <Widget>[
      for (final message in messages)
        if (message.role == ChatRole.user)
          UserBubble(text: message.content)
        else
          CoachBubble(
            text: message.content,
            footer: _footerOf(
              context,
              ref,
              message,
              offerPlan:
                  offerPlan &&
                  reply is CoachReplyIdle &&
                  identical(message, last),
            ),
          ),
      ...switch (reply) {
        CoachReplyIdle() => const <Widget>[],
        CoachReplyStreaming(:final text) => [
          CoachBubble(text: text, streaming: true),
        ],
        CoachReplyFailed(:final text, :final error) => [
          if (text.isNotEmpty) CoachBubble(text: text),
          ReplyFailure(
            message: error.message,
            onRetry: () =>
                ref.read(coachChatControllerProvider.notifier).retry(),
            onChangeModel: error is CoachReplyFailure && model != null
                ? () => _changeModel(context, ref, model)
                : null,
          ),
        ],
      },
    ];

    return ListView.separated(
      reverse: true,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) => items[items.length - 1 - index],
    );
  }
}

Future<void> _changeModel(
  BuildContext context,
  WidgetRef ref,
  AiModel current,
) async {
  final selected = await showAiModelSheet(context, current: current);
  if (selected == null || selected == current || !context.mounted) return;
  try {
    await ref.read(profileControllerProvider.notifier).updateAiModel(selected);
  } on AppException catch (error) {
    if (context.mounted) showAppSnackBar(context, error.message);
    return;
  }
  if (!context.mounted) return;
  await ref.read(coachChatControllerProvider.notifier).retry();
}

Widget? _footerOf(
  BuildContext context,
  WidgetRef ref,
  ChatMessage message, {
  required bool offerPlan,
}) {
  final hasProposal = message.proposal != null;
  if (!hasProposal && !offerPlan) return null;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (hasProposal) ProposalFooter(message: message),
      if (hasProposal && offerPlan) const SizedBox(height: 8),
      if (offerPlan)
        PrimaryButton(
          label: 'Generate my plan',
          variant: PrimaryButtonVariant.ai,
          onPressed: () => startPlanGeneration(context, ref),
        ),
    ],
  );
}
