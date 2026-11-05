import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/models/coach_stream_event.dart';
import '../data_sources/coach_remote_data_source.dart';
import '../data_sources/coach_sse_parser.dart';

part 'coach_repository.g.dart';

class CoachRepository {
  CoachRepository(
    this._remote, {
    this._idleTimeout = const Duration(seconds: 75),
  });

  final CoachRemoteDataSource _remote;
  final Duration _idleTimeout;

  Future<List<ChatMessage>> fetchMessages(String userId) =>
      runGuarded(() async {
        final rows = await _remote.fetchMessages(userId);
        return rows.reversed.map(ChatMessage.fromJson).toList();
      });

  Stream<CoachStreamEvent> sendMessage({
    required String text,
    required int weekday,
  }) => _reply({'message': text, 'weekday': weekday});

  Stream<CoachStreamEvent> retryMessage({
    required String messageId,
    required int weekday,
  }) => _reply({'retry_message_id': messageId, 'weekday': weekday});

  Future<String> applyProposal(String messageId) => runGuarded(() async {
    try {
      return await _remote.applyProposal(messageId);
    } on PostgrestException catch (error) {
      throw switch (error.code) {
        'RM001' || 'RM002' => const ProposalOutdated(),
        'RM003' => const PlanProfileMismatch(),
        _ => error,
      };
    }
  });

  Future<String?> fetchTip({required String planId, required String date}) =>
      runGuarded(() => _remote.fetchTip(planId: planId, date: date));

  Future<String> generateTip({required String date, required int weekday}) =>
      runGuarded(() => _remote.generateTip(date: date, weekday: weekday));

  Stream<CoachStreamEvent> _reply(Map<String, dynamic> body) =>
      guardStream(_openReply(body), map: _replyError);

  Stream<CoachStreamEvent> _openReply(Map<String, dynamic> body) async* {
    final bytes = await _remote.openReply(body);
    yield* parseCoachStream(bytes.timeout(_idleTimeout));
  }

  static AppException _replyError(Object error) => switch (error) {
    FunctionsFetchException() => const NetworkFailure(),
    FunctionException() || TimeoutException() => const CoachReplyFailure(),
    _ => switch (mapToAppException(error)) {
      UnknownFailure() => const CoachReplyFailure(),
      final mapped => mapped,
    },
  };
}

@Riverpod(keepAlive: true)
CoachRepository coachRepository(Ref ref) =>
    CoachRepository(CoachRemoteDataSource(ref.watch(supabaseClientProvider)));
