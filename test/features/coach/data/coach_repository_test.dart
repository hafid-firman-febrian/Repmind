import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/coach/data/repositories/coach_repository.dart';
import 'package:repmind/features/coach/domain/models/coach_stream_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../fixtures/coach_fixtures.dart';
import '../../../helpers/mocks.dart';

const _done =
    'data: {"type":"done","message_id":"m-1","proposal":null,"user_confirmed":false}\n\n';

Stream<List<int>> _bytes(List<String> parts) =>
    Stream.fromIterable(parts.map(utf8.encode));

void main() {
  late MockCoachRemoteDataSource remote;
  late CoachRepository repository;

  setUp(() {
    remote = MockCoachRemoteDataSource();
    repository = CoachRepository(remote);
  });

  test('fetchMessages returns the oldest first', () async {
    when(() => remote.fetchMessages('user-1')).thenAnswer(
      (_) async => [
        chatMessageRow(id: 'new', createdAt: '2026-11-05T09:00:00+00:00'),
        chatMessageRow(id: 'old', createdAt: '2026-11-05T08:00:00+00:00'),
      ],
    );

    final messages = await repository.fetchMessages('user-1');

    expect(messages.map((m) => m.id), ['old', 'new']);
  });

  test('sendMessage sends message and weekday', () async {
    when(
      () => remote.openReply(any()),
    ).thenAnswer((_) async => _bytes([_done]));

    final events = await repository
        .sendMessage(text: 'Hi coach', weekday: 4)
        .toList();

    expect(events.single, isA<CoachDone>());
    verify(
      () => remote.openReply({'message': 'Hi coach', 'weekday': 4}),
    ).called(1);
  });

  test('retryMessage sends retry_message_id and weekday', () async {
    when(
      () => remote.openReply(any()),
    ).thenAnswer((_) async => _bytes([_done]));

    await repository.retryMessage(messageId: 'u-1', weekday: 5).toList();

    verify(
      () => remote.openReply({'retry_message_id': 'u-1', 'weekday': 5}),
    ).called(1);
  });

  test('a FunctionException from coach-chat is CoachReplyFailure', () async {
    for (final error in <Object>[
      const FunctionsHttpException(status: 502),
      const FunctionsHttpException(status: 409),
      const FunctionsRelayException(status: 502),
    ]) {
      when(() => remote.openReply(any())).thenThrow(error);

      await expectLater(
        repository.sendMessage(text: 'Hi', weekday: 1).toList(),
        throwsA(isA<CoachReplyFailure>()),
      );
    }
  });

  test('a 409 from retryMessage is CoachRetryUnavailable', () async {
    when(
      () => remote.openReply(any()),
    ).thenThrow(const FunctionsHttpException(status: 409));

    await expectLater(
      repository.retryMessage(messageId: 'u-1', weekday: 1).toList(),
      throwsA(isA<CoachRetryUnavailable>()),
    );
  });

  test('other retryMessage failures stay CoachReplyFailure', () async {
    when(
      () => remote.openReply(any()),
    ).thenThrow(const FunctionsHttpException(status: 502));

    await expectLater(
      repository.retryMessage(messageId: 'u-1', weekday: 1).toList(),
      throwsA(isA<CoachReplyFailure>()),
    );
  });

  test('an error event in the stream is CoachReplyFailure', () async {
    when(() => remote.openReply(any())).thenAnswer(
      (_) async => _bytes(['data: {"type":"error","code":"save_failed"}\n\n']),
    );

    await expectLater(
      repository.sendMessage(text: 'Hi', weekday: 1).toList(),
      throwsA(isA<CoachReplyFailure>()),
    );
  });

  test('a dropped connection is NetworkFailure', () async {
    when(
      () => remote.openReply(any()),
    ).thenAnswer((_) async => Stream.error(const SocketException('lost')));

    await expectLater(
      repository.sendMessage(text: 'Hi', weekday: 1).toList(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('a send that cannot reach the function is NetworkFailure', () async {
    when(
      () => remote.openReply(any()),
    ).thenThrow(const FunctionsFetchException());

    await expectLater(
      repository.sendMessage(text: 'Hi', weekday: 1).toList(),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('an unexpected failure becomes CoachReplyFailure', () async {
    when(() => remote.openReply(any())).thenThrow(StateError('boom'));

    await expectLater(
      repository.sendMessage(text: 'Hi', weekday: 1).toList(),
      throwsA(isA<CoachReplyFailure>()),
    );
  });

  test('a stalled stream times out as CoachReplyFailure', () async {
    repository = CoachRepository(
      remote,
      idleTimeout: const Duration(milliseconds: 20),
    );
    final controller = StreamController<List<int>>();
    addTearDown(controller.close);
    when(
      () => remote.openReply(any()),
    ).thenAnswer((_) async => controller.stream);

    await expectLater(
      repository.sendMessage(text: 'Hi', weekday: 1).toList(),
      throwsA(isA<CoachReplyFailure>()),
    );
  });

  group('applyProposal', () {
    test('returns the new plan id', () async {
      when(
        () => remote.applyProposal('msg-2'),
      ).thenAnswer((_) async => 'plan-2');

      expect(await repository.applyProposal('msg-2'), 'plan-2');
    });

    test(
      'maps RM001 and RM002 to ProposalOutdated, RM003 to mismatch',
      () async {
        for (final code in ['RM001', 'RM002']) {
          when(
            () => remote.applyProposal('msg-2'),
          ).thenThrow(PostgrestException(message: 'x', code: code));
          await expectLater(
            repository.applyProposal('msg-2'),
            throwsA(isA<ProposalOutdated>()),
          );
        }
        when(
          () => remote.applyProposal('msg-2'),
        ).thenThrow(const PostgrestException(message: 'x', code: 'RM003'));
        await expectLater(
          repository.applyProposal('msg-2'),
          throwsA(isA<PlanProfileMismatch>()),
        );
      },
    );

    test('other errors go through the shared mapper', () async {
      when(
        () => remote.applyProposal('msg-2'),
      ).thenThrow(const SocketException('offline'));
      await expectLater(
        repository.applyProposal('msg-2'),
        throwsA(isA<NetworkFailure>()),
      );

      when(
        () => remote.applyProposal('msg-2'),
      ).thenThrow(const PostgrestException(message: 'x', code: '42501'));
      await expectLater(
        repository.applyProposal('msg-2'),
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  test('generateTip returns the tip text', () async {
    when(
      () => remote.generateTip(date: '2026-11-05', weekday: 4),
    ).thenAnswer((_) async => 'Warm up your shoulders first.');

    expect(
      await repository.generateTip(date: '2026-11-05', weekday: 4),
      'Warm up your shoulders first.',
    );
  });

  test('fetchTip returns null when absent', () async {
    when(
      () => remote.fetchTip(planId: 'plan-1', date: '2026-11-05'),
    ).thenAnswer((_) async => null);

    expect(
      await repository.fetchTip(planId: 'plan-1', date: '2026-11-05'),
      isNull,
    );
  });

  test('fetchTip returns the stored text', () async {
    when(
      () => remote.fetchTip(planId: 'plan-1', date: '2026-11-05'),
    ).thenAnswer((_) async => 'Stay hydrated.');

    expect(
      await repository.fetchTip(planId: 'plan-1', date: '2026-11-05'),
      'Stay hydrated.',
    );
  });
}
