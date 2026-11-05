import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../auth/presentation/controllers/auth_status_provider.dart';
import '../../../plan/domain/models/workout_plan_model.dart';
import '../../../plan/presentation/controllers/active_plan_controller.dart';
import '../../application/services/coach_rules.dart';
import '../../data/repositories/coach_repository.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/models/coach_stream_event.dart';
import '../states/coach_chat_state.dart';

part 'coach_chat_controller.g.dart';

@Riverpod(keepAlive: true)
class CoachChatController extends _$CoachChatController {
  Object? _session;
  StreamSubscription<CoachStreamEvent>? _subscription;
  Completer<void>? _finished;
  var _localMessages = 0;

  @override
  Future<CoachChatState> build() async {
    final session = _session = Object();
    ref.onDispose(() {
      _session = null;
      _subscription?.cancel();
      _subscription = null;
      final finished = _finished;
      _finished = null;
      if (finished != null && !finished.isCompleted) finished.complete();
    });
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const CoachChatState();
    final messages = await ref
        .read(coachRepositoryProvider)
        .fetchMessages(userId);
    if (!identical(session, _session)) return const CoachChatState();
    final last = messages.isEmpty ? null : messages.last;
    if (last == null || last.role != ChatRole.user) {
      return CoachChatState(messages: messages);
    }
    return CoachChatState(
      messages: messages,
      reply: CoachReplyFailed(
        text: '',
        error: const CoachReplyFailure(),
        pendingText: last.content,
        userMessageId: last.id,
      ),
    );
  }

  Future<void> send(String text) async {
    final current = state.value;
    if (current == null || current.reply is CoachReplyStreaming) return;
    if (!CoachRules.canSend(text)) return;
    final trimmed = text.trim();
    final localMessage = ChatMessage(
      id: 'local-${_localMessages++}',
      role: ChatRole.user,
      content: trimmed,
      createdAt: ref.read(clockProvider)(),
    );
    final session = _session;
    state = AsyncData(
      current.copyWith(
        messages: [...current.messages, localMessage],
        reply: const CoachReplyStreaming(''),
      ),
    );
    await _run(
      session: session,
      pendingText: trimmed,
      userMessageId: null,
      open: (weekday) => ref
          .read(coachRepositoryProvider)
          .sendMessage(text: trimmed, weekday: weekday),
    );
  }

  Future<void> retry() async {
    final current = state.value;
    if (current == null) return;
    final reply = current.reply;
    if (reply is! CoachReplyFailed) return;
    final session = _session;
    state = AsyncData(current.copyWith(reply: const CoachReplyStreaming('')));
    final userMessageId = reply.userMessageId;
    await _run(
      session: session,
      pendingText: reply.pendingText,
      userMessageId: userMessageId,
      open: (weekday) => userMessageId == null
          ? ref
                .read(coachRepositoryProvider)
                .sendMessage(text: reply.pendingText, weekday: weekday)
          : ref
                .read(coachRepositoryProvider)
                .retryMessage(messageId: userMessageId, weekday: weekday),
    );
  }

  Future<void> applyProposal(String messageId) async {
    final current = state.value;
    if (current == null || current.applyingMessageId != null) return;
    final session = _session;
    state = AsyncData(current.copyWith(applyingMessageId: messageId));
    try {
      final planId = await ref
          .read(coachRepositoryProvider)
          .applyProposal(messageId);
      final plan = await _refreshPlan();
      _update(session, (chat) {
        return chat.copyWith(
          messages: [
            for (final message in chat.messages)
              message.id == messageId
                  ? message.copyWith(
                      appliedPlanId: planId,
                      appliedPlanVersion: plan?.id == planId
                          ? plan?.version
                          : null,
                    )
                  : message,
          ],
          applyingMessageId: null,
        );
      });
    } catch (error) {
      if (error is ProposalOutdated) await _refreshPlan();
      _update(session, (chat) => chat.copyWith(applyingMessageId: null));
      rethrow;
    }
  }

  void clearAutoReview() {
    final current = state.value;
    if (current == null || current.autoReviewMessageId == null) return;
    state = AsyncData(current.copyWith(autoReviewMessageId: null));
  }

  Future<WorkoutPlan?> _refreshPlan() => ref
      .refresh(activePlanControllerProvider.future)
      .then<WorkoutPlan?>((plan) => plan, onError: (Object _) => null);

  void _update(
    Object? session,
    CoachChatState Function(CoachChatState) change,
  ) {
    if (!ref.mounted || !identical(session, _session)) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
  }

  Future<void> _run({
    required Object? session,
    required String pendingText,
    required String? userMessageId,
    required Stream<CoachStreamEvent> Function(int weekday) open,
  }) {
    final chat = state.value;
    if (chat == null) return Future.value();
    var targetId = chat.messages.last.id;
    var startedId = userMessageId;
    var buffer = '';
    var settled = false;
    final finished = Completer<void>();
    _finished = finished;

    bool alive() => ref.mounted && identical(session, _session);

    void settle() {
      settled = true;
      _subscription = null;
      if (!finished.isCompleted) finished.complete();
    }

    void fail(Object error) {
      if (settled) return;
      final failure = error is AppException ? error : const CoachReplyFailure();
      _update(
        session,
        (chat) => chat.copyWith(
          reply: CoachReplyFailed(
            text: buffer,
            error: failure,
            pendingText: pendingText,
            userMessageId: startedId,
          ),
        ),
      );
      settle();
    }

    final Stream<CoachStreamEvent> stream;
    try {
      stream = open(ref.read(clockProvider)().weekday);
    } catch (error) {
      fail(error);
      return finished.future;
    }

    _subscription = stream.listen(
      (event) {
        if (!alive() || settled) return;
        switch (event) {
          case CoachStarted(:final userMessageId):
            final previousId = targetId;
            targetId = userMessageId;
            startedId = userMessageId;
            _update(
              session,
              (chat) => chat.copyWith(
                messages: [
                  for (final message in chat.messages)
                    message.id == previousId
                        ? message.copyWith(id: userMessageId)
                        : message,
                ],
              ),
            );
          case CoachDelta(:final text):
            buffer += text;
            final partial = buffer;
            _update(
              session,
              (chat) => chat.copyWith(reply: CoachReplyStreaming(partial)),
            );
          case CoachDone(
            :final messageId,
            :final proposal,
            :final userConfirmed,
          ):
            final reply = ChatMessage(
              id: messageId,
              role: ChatRole.assistant,
              content: buffer,
              proposal: proposal,
              createdAt: ref.read(clockProvider)(),
            );
            _update(
              session,
              (chat) => chat.copyWith(
                messages: [...chat.messages, reply],
                reply: const CoachReplyIdle(),
                autoReviewMessageId: userConfirmed && proposal != null
                    ? messageId
                    : chat.autoReviewMessageId,
              ),
            );
            settle();
        }
      },
      onError: (Object error) {
        if (alive()) fail(error);
      },
      onDone: () {
        if (alive()) fail(const CoachReplyFailure());
        settle();
      },
      cancelOnError: true,
    );
    return finished.future;
  }
}
