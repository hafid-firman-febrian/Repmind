import '../../../../core/errors/app_exception.dart';
import '../../domain/models/chat_message_model.dart';

sealed class CoachReply {
  const CoachReply();
}

final class CoachReplyIdle extends CoachReply {
  const CoachReplyIdle();
}

final class CoachReplyStreaming extends CoachReply {
  const CoachReplyStreaming(this.text);

  final String text;
}

final class CoachReplyFailed extends CoachReply {
  const CoachReplyFailed({
    required this.text,
    required this.error,
    required this.pendingText,
    this.userMessageId,
  });

  final String text;
  final AppException error;
  final String pendingText;
  final String? userMessageId;
}

const Object _unset = Object();

class CoachChatState {
  const CoachChatState({
    this.messages = const [],
    this.reply = const CoachReplyIdle(),
    this.applyingMessageId,
    this.autoReviewMessageId,
  });

  final List<ChatMessage> messages;
  final CoachReply reply;
  final String? applyingMessageId;
  final String? autoReviewMessageId;

  CoachChatState copyWith({
    List<ChatMessage>? messages,
    CoachReply? reply,
    Object? applyingMessageId = _unset,
    Object? autoReviewMessageId = _unset,
  }) => CoachChatState(
    messages: messages ?? this.messages,
    reply: reply ?? this.reply,
    applyingMessageId: identical(applyingMessageId, _unset)
        ? this.applyingMessageId
        : applyingMessageId as String?,
    autoReviewMessageId: identical(autoReviewMessageId, _unset)
        ? this.autoReviewMessageId
        : autoReviewMessageId as String?,
  );
}
