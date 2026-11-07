import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/time/clock_provider.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/coach/data/repositories/coach_repository.dart';
import 'package:repmind/features/coach/domain/models/chat_message_model.dart';
import 'package:repmind/features/coach/domain/models/coach_stream_event.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_chat_controller.dart';
import 'package:repmind/features/coach/presentation/states/coach_chat_state.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';

import '../../../fixtures/coach_fixtures.dart';
import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/mocks.dart';

class _UserSwitch extends Notifier<String?> {
  @override
  String? build() => 'user-1';

  void set(String? value) => state = value;
}

final _userSwitchProvider = NotifierProvider<_UserSwitch, String?>(
  _UserSwitch.new,
);

void main() {
  late MockCoachRepository repository;
  late MockPlanRepository planRepository;
  late StreamController<CoachStreamEvent> events;

  setUp(() {
    repository = MockCoachRepository();
    planRepository = MockPlanRepository();
    events = StreamController<CoachStreamEvent>();
    addTearDown(() {
      if (!events.isClosed) events.close();
    });
    when(
      () => repository.fetchMessages('user-1'),
    ).thenAnswer((_) async => <ChatMessage>[]);
    when(
      () => planRepository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => samplePlan());
  });

  ProviderContainer createContainer({String? userId = 'user-1'}) {
    final container = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWith(
          (ref) => ref.watch(_userSwitchProvider),
        ),
        coachRepositoryProvider.overrideWithValue(repository),
        planRepositoryProvider.overrideWithValue(planRepository),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 5, 9)),
      ],
      retry: (_, _) => null,
    );
    container.read(_userSwitchProvider.notifier).set(userId);
    container.listen(coachChatControllerProvider, (_, _) {});
    container.listen(activePlanControllerProvider, (_, _) {});
    return container;
  }

  Future<CoachChatState> loaded(ProviderContainer container) =>
      container.read(coachChatControllerProvider.future);

  CoachChatState current(ProviderContainer container) =>
      container.read(coachChatControllerProvider).requireValue;

  void streamSend(String text) {
    when(
      () => repository.sendMessage(text: text, weekday: 4),
    ).thenAnswer((_) => events.stream);
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  int userMessages(ProviderContainer container) => current(
    container,
  ).messages.where((message) => message.role == ChatRole.user).length;

  test('build loads the history', () async {
    when(() => repository.fetchMessages('user-1')).thenAnswer(
      (_) async => [
        sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello'),
        sampleCoachMessage(id: 'm2', content: 'Hi'),
      ],
    );
    final container = createContainer();

    final state = await loaded(container);

    expect(state.messages.map((message) => message.id), ['m1', 'm2']);
    expect(state.reply, isA<CoachReplyIdle>());
  });

  test('build with no user is empty', () async {
    final container = createContainer(userId: null);

    final state = await loaded(container);

    expect(state.messages, isEmpty);
    verifyNever(() => repository.fetchMessages(any()));
  });

  test('an unanswered last message loads as failed', () async {
    when(() => repository.fetchMessages('user-1')).thenAnswer(
      (_) async => [
        sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello'),
      ],
    );
    final container = createContainer();

    final reply = (await loaded(container)).reply;

    expect(reply, isA<CoachReplyFailed>());
    reply as CoachReplyFailed;
    expect(reply.text, '');
    expect(reply.userMessageId, 'm1');
    expect(reply.pendingText, 'Hello');
    expect(reply.error, isA<CoachReplyFailure>());
  });

  test('send shows the user message and streams the reply', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();

    expect(current(container).messages.single.content, 'Hi coach');
    expect(current(container).messages.single.role, ChatRole.user);
    expect(current(container).reply, isA<CoachReplyStreaming>());

    events.add(const CoachDelta(text: 'Hi'));
    await pump();
    final streaming = current(container).reply as CoachReplyStreaming;
    expect(streaming.text, 'Hi');

    events.add(const CoachDelta(text: ' there'));
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await sending;

    final state = current(container);
    expect(state.reply, isA<CoachReplyIdle>());
    expect(state.messages.last.id, 'a1');
    expect(state.messages.last.role, ChatRole.assistant);
    expect(state.messages.last.content, 'Hi there');
    expect(state.messages.last.createdAt, DateTime(2026, 11, 5, 9));
    expect(state.autoReviewMessageId, isNull);
  });

  test('started replaces the local id', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    expect(current(container).messages.single.id, startsWith('local-'));

    events.add(const CoachStarted(userMessageId: 'u1'));
    await pump();

    expect(current(container).messages.single.id, 'u1');
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await sending;
  });

  test('send is ignored while streaming', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    await notifier.send('Hi coach');

    verify(
      () => repository.sendMessage(text: 'Hi coach', weekday: 4),
    ).called(1);
    expect(userMessages(container), 1);
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await sending;
  });

  test('a stream failure keeps the partial text', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    events.add(const CoachDelta(text: 'Start '));
    events.add(const CoachDelta(text: 'around'));
    events.addError(const NetworkFailure());
    await sending;

    final state = current(container);
    final reply = state.reply as CoachReplyFailed;
    expect(reply.text, 'Start around');
    expect(reply.error, isA<NetworkFailure>());
    expect(reply.pendingText, 'Hi coach');
    expect(reply.userMessageId, isNull);
    expect(state.messages.map((message) => message.role), [ChatRole.user]);
  });

  test('a non-app error becomes a reply failure', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    events.addError(StateError('boom'));
    await sending;

    final reply = current(container).reply as CoachReplyFailed;
    expect(reply.error, isA<CoachReplyFailure>());
  });

  test('a stream that ends without done fails', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    events.add(const CoachDelta(text: 'Partial'));
    await events.close();
    await sending;

    final reply = current(container).reply as CoachReplyFailed;
    expect(reply.text, 'Partial');
    expect(reply.error, isA<CoachReplyFailure>());
  });

  test('retry after started uses retryMessage', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);
    final first = notifier.send('Hi coach');
    await pump();
    events.add(const CoachStarted(userMessageId: 'm1'));
    events.addError(const CoachReplyFailure());
    await first;
    final retryEvents = StreamController<CoachStreamEvent>();
    addTearDown(retryEvents.close);
    when(
      () => repository.retryMessage(messageId: 'm1', weekday: 4),
    ).thenAnswer((_) => retryEvents.stream);

    final retrying = notifier.retry();
    await pump();

    expect(current(container).reply, isA<CoachReplyStreaming>());
    retryEvents.add(const CoachStarted(userMessageId: 'm1'));
    retryEvents.add(const CoachDelta(text: 'Answer'));
    retryEvents.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await retrying;

    verify(
      () => repository.retryMessage(messageId: 'm1', weekday: 4),
    ).called(1);
    verify(
      () => repository.sendMessage(text: 'Hi coach', weekday: 4),
    ).called(1);
    expect(userMessages(container), 1);
    expect(current(container).messages.last.content, 'Answer');
    expect(current(container).reply, isA<CoachReplyIdle>());
  });

  test('retry before started resends the text', () async {
    final attempts = [
      StreamController<CoachStreamEvent>(),
      StreamController<CoachStreamEvent>(),
    ];
    addTearDown(() {
      for (final attempt in attempts) {
        attempt.close();
      }
    });
    var calls = 0;
    when(
      () => repository.sendMessage(text: 'Hi coach', weekday: 4),
    ).thenAnswer((_) => attempts[calls++].stream);
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);
    final first = notifier.send('Hi coach');
    await pump();
    attempts[0].addError(const NetworkFailure());
    await first;

    final retrying = notifier.retry();
    await pump();
    attempts[1].add(const CoachStarted(userMessageId: 'u1'));
    attempts[1].add(const CoachDelta(text: 'Answer'));
    attempts[1].add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await retrying;

    expect(calls, 2);
    verifyNever(
      () => repository.retryMessage(
        messageId: any(named: 'messageId'),
        weekday: any(named: 'weekday'),
      ),
    );
    expect(userMessages(container), 1);
    expect(current(container).messages.first.id, 'u1');
    expect(current(container).messages.last.content, 'Answer');
  });

  test('retry of a message loaded unanswered uses retryMessage', () async {
    when(() => repository.fetchMessages('user-1')).thenAnswer(
      (_) async => [
        sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello'),
      ],
    );
    when(
      () => repository.retryMessage(messageId: 'm1', weekday: 4),
    ).thenAnswer((_) => events.stream);
    final container = createContainer();
    await loaded(container);

    final retrying = container
        .read(coachChatControllerProvider.notifier)
        .retry();
    await pump();
    events.add(const CoachDelta(text: 'Answer'));
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await retrying;

    expect(userMessages(container), 1);
    expect(current(container).messages.last.content, 'Answer');
  });

  test('a retry the server refuses reloads the saved reply', () async {
    var loads = 0;
    when(() => repository.fetchMessages('user-1')).thenAnswer((_) async {
      return loads++ == 0
          ? [sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello')]
          : [
              sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello'),
              sampleCoachMessage(id: 'a1', content: 'Saved answer'),
            ];
    });
    when(
      () => repository.retryMessage(messageId: 'm1', weekday: 4),
    ).thenAnswer((_) => events.stream);
    final container = createContainer();
    await loaded(container);

    final retrying = container
        .read(coachChatControllerProvider.notifier)
        .retry();
    await pump();
    events.addError(const CoachRetryUnavailable());
    await retrying;
    final state = await loaded(container);

    expect(loads, 2);
    expect(state.reply, isA<CoachReplyIdle>());
    expect(state.messages.last.content, 'Saved answer');
  });

  test('a failed send stays failed and does not reload', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Hi coach');
    await pump();
    events.addError(const CoachReplyFailure());
    await sending;

    expect(current(container).reply, isA<CoachReplyFailed>());
    verify(() => repository.fetchMessages('user-1')).called(1);
  });

  test('a confirmed proposal sets autoReviewMessageId', () async {
    streamSend('Yes, swap it');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);

    final sending = notifier.send('Yes, swap it');
    await pump();
    events.add(const CoachDelta(text: "Here's the change I suggest."));
    events.add(
      CoachDone(
        messageId: 'a1',
        proposal: sampleProposal(),
        userConfirmed: true,
      ),
    );
    await sending;

    expect(current(container).autoReviewMessageId, 'a1');
    expect(current(container).messages.last.proposal, isNotNull);

    notifier.clearAutoReview();

    expect(current(container).autoReviewMessageId, isNull);
  });

  test('changing user stops the stream and clears the chat', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);
    unawaited(notifier.send('Hi coach'));
    await pump();
    expect(events.hasListener, isTrue);
    when(
      () => repository.fetchMessages('user-2'),
    ).thenAnswer((_) async => <ChatMessage>[]);

    container.read(_userSwitchProvider.notifier).set('user-2');
    final state = await loaded(container);
    events.add(const CoachDelta(text: 'late'));
    await pump();

    expect(events.hasListener, isFalse);
    expect(state.messages, isEmpty);
    expect(current(container).messages, isEmpty);
    expect(current(container).reply, isA<CoachReplyIdle>());
  });

  group('applyProposal', () {
    void answerPlans(List<WorkoutPlan?> plans) {
      when(
        () => planRepository.fetchActivePlan('user-1'),
      ).thenAnswer((_) async => plans.removeAt(0));
    }

    void loadProposal() {
      when(() => repository.fetchMessages('user-1')).thenAnswer(
        (_) async => [
          sampleCoachMessage(id: 'm1', role: 'user', content: 'Swap it'),
          sampleCoachMessage(id: 'm2', withProposal: true),
        ],
      );
    }

    test('refreshes the plan and marks the message', () async {
      loadProposal();
      answerPlans([samplePlan(), samplePlan(version: 2)]);
      when(
        () => repository.applyProposal('m2'),
      ).thenAnswer((_) async => 'plan-2');
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);

      await container
          .read(coachChatControllerProvider.notifier)
          .applyProposal('m2');

      final message = current(container).messages.last;
      expect(message.appliedPlanId, 'plan-2');
      expect(message.appliedPlanVersion, 2);
      expect(current(container).applyingMessageId, isNull);
      expect(container.read(activePlanControllerProvider).value!.version, 2);
    });

    test('a second apply while applying is ignored', () async {
      loadProposal();
      answerPlans([samplePlan(), samplePlan(version: 2)]);
      final pending = Completer<String>();
      when(
        () => repository.applyProposal('m2'),
      ).thenAnswer((_) => pending.future);
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);
      final notifier = container.read(coachChatControllerProvider.notifier);

      final first = notifier.applyProposal('m2');
      await pump();
      expect(current(container).applyingMessageId, 'm2');
      await notifier.applyProposal('m2');
      pending.complete('plan-2');
      await first;

      verify(() => repository.applyProposal('m2')).called(1);
    });

    test('a failed apply clears the state and rethrows', () async {
      loadProposal();
      answerPlans([samplePlan(), samplePlan(version: 2)]);
      when(
        () => repository.applyProposal('m2'),
      ).thenThrow(const ProposalOutdated());
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);

      await expectLater(
        container
            .read(coachChatControllerProvider.notifier)
            .applyProposal('m2'),
        throwsA(isA<ProposalOutdated>()),
      );

      expect(current(container).applyingMessageId, isNull);
      expect(current(container).messages.last.appliedPlanId, isNull);
    });

    test('ProposalOutdated refreshes the plan', () async {
      loadProposal();
      answerPlans([samplePlan(), samplePlan(version: 2)]);
      when(
        () => repository.applyProposal('m2'),
      ).thenThrow(const ProposalOutdated());
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);

      await expectLater(
        container
            .read(coachChatControllerProvider.notifier)
            .applyProposal('m2'),
        throwsA(isA<ProposalOutdated>()),
      );

      expect(container.read(activePlanControllerProvider).value!.version, 2);
    });

    test('another failure leaves the plan alone and rethrows', () async {
      loadProposal();
      answerPlans([samplePlan()]);
      when(
        () => repository.applyProposal('m2'),
      ).thenThrow(const NetworkFailure());
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);

      await expectLater(
        container
            .read(coachChatControllerProvider.notifier)
            .applyProposal('m2'),
        throwsA(isA<NetworkFailure>()),
      );

      expect(current(container).applyingMessageId, isNull);
      verify(() => planRepository.fetchActivePlan('user-1')).called(1);
    });

    test('a plan that fails to reload leaves the version empty', () async {
      loadProposal();
      var loads = 0;
      when(() => planRepository.fetchActivePlan('user-1')).thenAnswer((
        _,
      ) async {
        loads++;
        if (loads == 1) return samplePlan();
        throw const NetworkFailure();
      });
      when(
        () => repository.applyProposal('m2'),
      ).thenAnswer((_) async => 'plan-2');
      final container = createContainer();
      await loaded(container);
      await container.read(activePlanControllerProvider.future);

      await container
          .read(coachChatControllerProvider.notifier)
          .applyProposal('m2');

      final message = current(container).messages.last;
      expect(message.appliedPlanId, 'plan-2');
      expect(message.appliedPlanVersion, isNull);
      expect(current(container).applyingMessageId, isNull);
    });
  });

  test('an unconfirmed proposal does not open the review', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);

    final sending = container
        .read(coachChatControllerProvider.notifier)
        .send('Hi coach');
    await pump();
    events.add(
      CoachDone(
        messageId: 'a1',
        proposal: sampleProposal(),
        userConfirmed: false,
      ),
    );
    await sending;

    expect(current(container).messages.last.proposal, isNotNull);
    expect(current(container).autoReviewMessageId, isNull);
  });

  test('a confirmation without a proposal does not open the review', () async {
    streamSend('Yes, swap it');
    final container = createContainer();
    await loaded(container);

    final sending = container
        .read(coachChatControllerProvider.notifier)
        .send('Yes, swap it');
    await pump();
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: true),
    );
    await sending;

    expect(current(container).autoReviewMessageId, isNull);
  });

  test('send completes when the user changes mid-stream', () async {
    streamSend('Hi coach');
    final container = createContainer();
    await loaded(container);
    final sending = container
        .read(coachChatControllerProvider.notifier)
        .send('Hi coach');
    await pump();
    when(
      () => repository.fetchMessages('user-2'),
    ).thenAnswer((_) async => <ChatMessage>[]);

    container.read(_userSwitchProvider.notifier).set('user-2');
    await loaded(container);

    await sending.timeout(const Duration(seconds: 2));
  });

  test('a history that loads late for the old user is discarded', () async {
    final slow = Completer<List<ChatMessage>>();
    when(
      () => repository.fetchMessages('user-1'),
    ).thenAnswer((_) => slow.future);
    when(() => repository.fetchMessages('user-2')).thenAnswer(
      (_) async => [sampleCoachMessage(id: 'b1', content: 'New answer')],
    );
    final container = createContainer();
    await pump();

    container.read(_userSwitchProvider.notifier).set('user-2');
    await loaded(container);
    slow.complete([sampleCoachMessage(id: 'a-old', content: 'OLD ANSWER')]);
    await pump();

    expect(current(container).messages.map((message) => message.id), ['b1']);
  });

  test('a finished stream does not drop the next stream handle', () async {
    final second = StreamController<CoachStreamEvent>();
    addTearDown(second.close);
    streamSend('one');
    when(
      () => repository.sendMessage(text: 'two', weekday: 4),
    ).thenAnswer((_) => second.stream);
    final container = createContainer();
    await loaded(container);
    final notifier = container.read(coachChatControllerProvider.notifier);
    final first = notifier.send('one');
    await pump();
    events.add(
      const CoachDone(messageId: 'a1', proposal: null, userConfirmed: false),
    );
    await first;
    final reply = notifier.send('two');
    await pump();
    expect(second.hasListener, isTrue);

    unawaited(events.close());
    await pump();
    when(
      () => repository.fetchMessages('user-2'),
    ).thenAnswer((_) async => <ChatMessage>[]);
    container.read(_userSwitchProvider.notifier).set('user-2');
    await loaded(container);

    expect(second.hasListener, isFalse);
    await reply.timeout(const Duration(seconds: 2));
  });

  group('after a direct user change', () {
    Future<ProviderContainer> loadedAsUserOne() async {
      when(() => repository.fetchMessages('user-1')).thenAnswer(
        (_) async => [
          sampleCoachMessage(id: 'm1', role: 'user', content: 'OLD SECRET'),
          sampleCoachMessage(
            id: 'm2',
            content: 'OLD ANSWER',
            withProposal: true,
          ),
        ],
      );
      final container = createContainer();
      await loaded(container);
      return container;
    }

    Future<void> switchToUserTwo(ProviderContainer container) async {
      container.read(_userSwitchProvider.notifier).set('user-2');
      await pump();
    }

    test('send is ignored while the new history loads', () async {
      final container = await loadedAsUserOne();
      final reload = Completer<List<ChatMessage>>();
      when(
        () => repository.fetchMessages('user-2'),
      ).thenAnswer((_) => reload.future);
      streamSend('as user 2');

      await switchToUserTwo(container);
      expect(container.read(coachChatControllerProvider).isLoading, isTrue);
      unawaited(
        container.read(coachChatControllerProvider.notifier).send('as user 2'),
      );
      await pump();
      reload.complete([]);
      final state = await loaded(container);

      verifyNever(
        () => repository.sendMessage(
          text: any(named: 'text'),
          weekday: any(named: 'weekday'),
        ),
      );
      expect(events.hasListener, isFalse);
      expect(state.messages, isEmpty);
      expect(state.reply, isA<CoachReplyIdle>());
    });

    test('send and apply are ignored after the new history fails', () async {
      final container = await loadedAsUserOne();
      when(
        () => repository.fetchMessages('user-2'),
      ).thenThrow(const NetworkFailure());
      streamSend('as user 2');
      final notifier = container.read(coachChatControllerProvider.notifier);

      await switchToUserTwo(container);
      await pump();
      expect(container.read(coachChatControllerProvider).hasError, isTrue);
      unawaited(notifier.send('as user 2'));
      unawaited(notifier.applyProposal('m2'));
      await pump();

      verifyNever(
        () => repository.sendMessage(
          text: any(named: 'text'),
          weekday: any(named: 'weekday'),
        ),
      );
      verifyNever(() => repository.applyProposal(any()));
      expect(container.read(coachChatControllerProvider).hasError, isTrue);
      expect(events.hasListener, isFalse);
    });

    test('retry is ignored while the new history loads', () async {
      when(() => repository.fetchMessages('user-1')).thenAnswer(
        (_) async => [
          sampleCoachMessage(id: 'm1', role: 'user', content: 'Hello'),
        ],
      );
      final container = createContainer();
      await loaded(container);
      final reload = Completer<List<ChatMessage>>();
      when(
        () => repository.fetchMessages('user-2'),
      ).thenAnswer((_) => reload.future);

      await switchToUserTwo(container);
      await container.read(coachChatControllerProvider.notifier).retry();

      verifyNever(
        () => repository.retryMessage(
          messageId: any(named: 'messageId'),
          weekday: any(named: 'weekday'),
        ),
      );
      expect(container.read(coachChatControllerProvider).isLoading, isTrue);
      reload.complete([]);
    });

    test('clearAutoReview is ignored while the new history loads', () async {
      streamSend('Yes, swap it');
      final container = createContainer();
      await loaded(container);
      final sending = container
          .read(coachChatControllerProvider.notifier)
          .send('Yes, swap it');
      await pump();
      events.add(
        CoachDone(
          messageId: 'a1',
          proposal: sampleProposal(),
          userConfirmed: true,
        ),
      );
      await sending;
      final reload = Completer<List<ChatMessage>>();
      when(
        () => repository.fetchMessages('user-2'),
      ).thenAnswer((_) => reload.future);

      await switchToUserTwo(container);
      container.read(coachChatControllerProvider.notifier).clearAutoReview();

      expect(container.read(coachChatControllerProvider).isLoading, isTrue);
      reload.complete([]);
    });

    test('a stale apply does not touch the new account', () async {
      final pending = Completer<String>();
      when(
        () => repository.applyProposal('m2'),
      ).thenAnswer((_) => pending.future);
      when(
        () => planRepository.fetchActivePlan('user-2'),
      ).thenAnswer((_) async => samplePlan());
      when(() => repository.fetchMessages('user-2')).thenAnswer(
        (_) async => [
          sampleCoachMessage(id: 'm1', role: 'user', content: 'Swap it'),
          sampleCoachMessage(id: 'm2', withProposal: true),
        ],
      );
      final container = await loadedAsUserOne();
      final applying = container
          .read(coachChatControllerProvider.notifier)
          .applyProposal('m2');
      await pump();

      container.read(_userSwitchProvider.notifier).set('user-2');
      await loaded(container);
      pending.complete('plan-2');
      await applying;

      final state = current(container);
      expect(state.messages.last.appliedPlanId, isNull);
      expect(state.applyingMessageId, isNull);
    });
  });
}
