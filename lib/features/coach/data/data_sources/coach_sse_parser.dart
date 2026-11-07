import 'dart:convert';

import '../../../../core/errors/app_exception.dart';
import '../../domain/models/coach_stream_event.dart';
import '../../domain/models/plan_proposal_model.dart';

const _dataPrefix = 'data:';

Stream<CoachStreamEvent> parseCoachStream(Stream<List<int>> bytes) async* {
  final lines = bytes.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    if (!line.startsWith(_dataPrefix)) continue;
    final json =
        jsonDecode(line.substring(_dataPrefix.length).trim())
            as Map<String, dynamic>;
    switch (json['type']) {
      case 'started':
        yield CoachStarted(userMessageId: json['user_message_id'] as String);
      case 'delta':
        yield CoachDelta(text: json['text'] as String);
      case 'done':
        final proposal = json['proposal'] as Map<String, dynamic>?;
        yield CoachDone(
          messageId: json['message_id'] as String,
          proposal: proposal == null ? null : PlanProposal.fromJson(proposal),
          userConfirmed: json['user_confirmed'] as bool,
        );
        return;
      case 'error':
        throw const CoachReplyFailure();
    }
  }
  throw const CoachReplyFailure();
}
