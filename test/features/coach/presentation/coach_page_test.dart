import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/core/widgets/selectable_card.dart';
import 'package:repmind/features/coach/application/services/coach_rules.dart';
import 'package:repmind/features/coach/domain/models/chat_message_model.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_chat_controller.dart';
import 'package:repmind/features/coach/presentation/pages/coach_page.dart';
import 'package:repmind/features/coach/presentation/states/coach_chat_state.dart';
import 'package:repmind/features/coach/presentation/widgets/coach_bubbles.dart';
import 'package:repmind/features/coach/presentation/widgets/coach_input_bar.dart';
import 'package:repmind/features/coach/presentation/widgets/review_change_sheet.dart';
import 'package:repmind/features/coach/presentation/widgets/streaming_dots.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';
import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_active_plan_controller.dart';
import '../../../fakes/fake_coach_chat_controller.dart';
import '../../../fakes/fake_plan_generation_controller.dart';
import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/coach_fixtures.dart';
import '../../../fixtures/plan_fixtures.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/pump_router.dart';

class _ThrowingCoachChatController extends FakeCoachChatController {
  _ThrowingCoachChatController();

  @override
  Future<CoachChatState> build() async => throw const NetworkFailure();
}

class _LoadingCoachChatController extends FakeCoachChatController {
  _LoadingCoachChatController();

  @override
  Future<CoachChatState> build() => Completer<CoachChatState>().future;
}

void main() {
  final userMessage = sampleCoachMessage(
    id: 'u1',
    role: 'user',
    content: 'How often should I train?',
  );
  final coachMessage = sampleCoachMessage(
    id: 'c1',
    content: 'Three full-body sessions a week is a solid start.',
  );

  Future<FakeCoachChatController> pumpCoach(
    WidgetTester tester, {
    CoachChatState state = const CoachChatState(),
    WorkoutPlan? plan,
    bool noPlan = false,
    FakeCoachChatController? controller,
    Profile? profile,
    FakeProfileController? profileController,
    bool tickers = true,
  }) async {
    useTallScreen(tester);
    final fake = controller ?? FakeCoachChatController(state);
    final generation = FakePlanGenerationController();
    await pumpRouter(
      tester,
      initialLocation: AppRoutes.coach,
      overrides: [
        profileControllerProvider.overrideWith(
          () =>
              profileController ??
              FakeProfileController(profile ?? sampleProfile()),
        ),
        activePlanControllerProvider.overrideWith(
          () => FakeActivePlanController(noPlan ? null : plan ?? samplePlan()),
        ),
        planGenerationControllerProvider.overrideWith(() => generation),
        coachChatControllerProvider.overrideWith(() => fake),
      ],
      routes: [
        GoRoute(
          path: AppRoutes.coach,
          builder: (_, _) =>
              TickerMode(enabled: tickers, child: const CoachPage()),
        ),
        GoRoute(
          path: AppRoutes.generating,
          builder: (_, _) => const Text('generating'),
        ),
        GoRoute(
          path: AppRoutes.workoutDay,
          builder: (_, state) => Text('day ${state.pathParameters['day']}'),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();
    return fake;
  }

  Finder sendButton() => find.byTooltip('Send');

  bool sendEnabled(WidgetTester tester) =>
      tester
          .widget<InkWell>(
            find.descendant(of: sendButton(), matching: find.byType(InkWell)),
          )
          .onTap !=
      null;

  testWidgets('shows the header and context chip', (tester) async {
    await pumpCoach(tester);

    expect(find.text('COACH'), findsOneWidget);
    expect(find.text('Knows your goal and plan'), findsOneWidget);
    expect(find.text('Using plan v1 · Build muscle'), findsOneWidget);
  });

  testWidgets('hides the context chip while the goal is unknown', (
    tester,
  ) async {
    await pumpCoach(tester, profile: sampleProfile(onboarded: false));

    expect(find.textContaining('Build muscle'), findsNothing);
    expect(find.textContaining('Using plan'), findsNothing);
    expect(find.textContaining('No plan yet'), findsNothing);
  });

  testWidgets(
    'no plan shows the no-plan chip and the generate button under the last reply',
    (tester) async {
      await pumpCoach(
        tester,
        noPlan: true,
        state: CoachChatState(messages: [userMessage, coachMessage]),
      );

      expect(find.text('No plan yet · Build muscle'), findsOneWidget);
      expect(find.text('Generate my plan'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CoachBubble),
          matching: find.text('Generate my plan'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Generate my plan'));
      await tester.pumpAndSettle();

      expect(find.text('generating'), findsOneWidget);
    },
  );

  testWidgets('with a plan there is no generate button', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(messages: [userMessage, coachMessage]),
    );

    expect(find.text('Generate my plan'), findsNothing);
  });

  testWidgets('an empty chat shows the three suggestions', (tester) async {
    await pumpCoach(tester);

    expect(find.text('Ask me about your training'), findsOneWidget);
    expect(
      find.text("I know your goal, your equipment, and this week's plan."),
      findsOneWidget,
    );
    for (final suggestion in CoachRules.suggestions) {
      expect(find.text(suggestion), findsOneWidget);
    }
  });

  testWidgets('tapping a suggestion sends it', (tester) async {
    final fake = await pumpCoach(tester);

    await tester.tap(find.text('My shoulder feels tight today'));
    await tester.pump();

    expect(fake.sendCalls, ['My shoulder feels tight today']);
  });

  testWidgets('typing and sending clears the field', (tester) async {
    final fake = await pumpCoach(tester);

    await tester.enterText(find.byType(TextField), '  Hello coach  ');
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pump();

    expect(fake.sendCalls, ['  Hello coach  ']);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('the send button is disabled for blank text', (tester) async {
    final fake = await pumpCoach(tester);

    expect(sendEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(sendEnabled(tester), isFalse);
    await tester.tap(sendButton());
    await tester.pump();
    expect(fake.sendCalls, isEmpty);

    await tester.enterText(find.byType(TextField), 'Hi');
    await tester.pump();
    expect(sendEnabled(tester), isTrue);
  });

  testWidgets('the field stops at 1000 characters', (tester) async {
    await pumpCoach(tester);

    await tester.enterText(find.byType(TextField), 'a' * 1100);
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text.length,
      CoachRules.maxMessageLength,
    );
    expect(find.text('1000/1000'), findsNothing);
  });

  testWidgets('input is disabled while streaming', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [userMessage],
        reply: const CoachReplyStreaming(''),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Another question');
    await tester.pump();

    expect(sendEnabled(tester), isFalse);
    for (final suggestion in CoachRules.suggestions) {
      expect(find.text(suggestion), findsNothing);
    }
  });

  testWidgets('streaming text shows with the dots', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [userMessage],
        reply: const CoachReplyStreaming('Start around 60%'),
      ),
    );

    expect(
      find.textContaining('Start around 60%', findRichText: true),
      findsOneWidget,
    );
    expect(find.byType(StreamingDots), findsOneWidget);
  });

  testWidgets('a reply that is done shows no dots', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(messages: [userMessage, coachMessage]),
    );

    expect(find.byType(StreamingDots), findsNothing);
  });

  testWidgets('a failed reply keeps the partial text and offers Try again', (
    tester,
  ) async {
    final fake = await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [userMessage],
        reply: const CoachReplyFailed(
          text: 'Start around 60% of your usual',
          error: CoachReplyFailure(),
          pendingText: 'How often should I train?',
        ),
      ),
    );

    expect(find.text('Start around 60% of your usual'), findsOneWidget);
    expect(find.text(const CoachReplyFailure().message), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(fake.retryCalls, 1);
  });

  testWidgets('an unanswered message with no partial text offers Try again', (
    tester,
  ) async {
    final fake = await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [userMessage],
        reply: const CoachReplyFailed(
          text: '',
          error: CoachReplyFailure(),
          pendingText: 'How often should I train?',
          userMessageId: 'u1',
        ),
      ),
    );

    expect(find.byType(CoachBubble), findsNothing);
    expect(find.text(const CoachReplyFailure().message), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(fake.retryCalls, 1);
  });

  testWidgets('markdown renders bold text', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [
          userMessage,
          sampleCoachMessage(content: 'Swap for **lateral raises** today'),
        ],
      ),
    );

    expect(find.textContaining('**'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('lateral raises'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('markdown images and links are inert', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [
          userMessage,
          sampleCoachMessage(
            content:
                '![x](http://example.com/a.png) and [site](http://example.com)',
          ),
        ],
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('site', findRichText: true), findsOneWidget);

    await tester.tap(find.textContaining('site', findRichText: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CoachPage), findsOneWidget);
  });

  testWidgets('the dots stop animating when animations are disabled', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [userMessage],
        reply: const CoachReplyStreaming(''),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(StreamingDots), findsOneWidget);
  });

  testWidgets('a load error offers a retry', (tester) async {
    await pumpCoach(tester, controller: _ThrowingCoachChatController());

    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(CoachInputBar), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('shows a spinner while the chat loads', (tester) async {
    await pumpCoach(tester, controller: _LoadingCoachChatController());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CoachInputBar), findsNothing);
  });

  testWidgets('user messages and coach replies both show', (tester) async {
    await pumpCoach(
      tester,
      state: CoachChatState(
        messages: [
          userMessage,
          coachMessage,
          ChatMessage(
            id: 'u2',
            role: ChatRole.user,
            content: 'Ok. How heavy should I go?',
            createdAt: DateTime(2026, 11, 5),
          ),
        ],
      ),
    );

    expect(find.byType(UserBubble), findsNWidgets(2));
    expect(find.byType(CoachBubble), findsOneWidget);
    expect(find.text('How often should I train?'), findsOneWidget);
  });

  group('proposals', () {
    final proposalMessage = sampleCoachMessage(id: 'c1', withProposal: true);
    final otherPlanMessage = ChatMessage.fromJson(
      chatMessageRow(
        id: 'c1',
        role: 'assistant',
        content: "Here's the change I suggest.",
        proposal: proposalRow(basedOnPlanId: 'plan-0'),
      ),
    );
    final withoutDayTwo = WorkoutPlan.fromJson(
      workoutPlanRow(
        days: sampleDayRows().where((day) => day['day_number'] != 2).toList(),
      ),
    );

    testWidgets(
      'a pending proposal shows Review change, which opens the sheet',
      (tester) async {
        await pumpCoach(
          tester,
          state: CoachChatState(messages: [userMessage, proposalMessage]),
        );

        expect(find.text('Review change'), findsOneWidget);
        expect(
          find.text('Your plan has changed since this suggestion.'),
          findsNothing,
        );

        await tester.tap(find.text('Review change'));
        await tester.pumpAndSettle();

        expect(find.byType(ReviewChangeSheet), findsOneWidget);
        expect(find.text('UPPER BODY PUSH'), findsOneWidget);
        expect(find.text('Apply as v2'), findsOneWidget);
      },
    );

    testWidgets('applying from the sheet calls the controller', (tester) async {
      final fake = await pumpCoach(
        tester,
        state: CoachChatState(messages: [userMessage, proposalMessage]),
      );

      await tester.tap(find.text('Review change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply as v2'));
      await tester.pumpAndSettle();

      expect(fake.applyCalls, ['c1']);
      expect(find.byType(ReviewChangeSheet), findsNothing);
    });

    testWidgets('an applied proposal shows Plan updated to v2 and View plan', (
      tester,
    ) async {
      await pumpCoach(
        tester,
        plan: samplePlan(version: 2),
        state: CoachChatState(
          messages: [
            userMessage,
            sampleCoachMessage(
              id: 'c1',
              withProposal: true,
              appliedPlanId: 'plan-2',
              appliedPlanVersion: 2,
            ),
          ],
        ),
      );

      expect(find.text('Plan updated to v2'), findsOneWidget);
      expect(find.text('Review change'), findsNothing);

      await tester.tap(find.text('View plan'));
      await tester.pumpAndSettle();

      expect(find.text('day 2'), findsOneWidget);
    });

    testWidgets(
      'an applied proposal without a known version says Plan updated',
      (tester) async {
        await pumpCoach(
          tester,
          state: CoachChatState(
            messages: [
              userMessage,
              sampleCoachMessage(
                id: 'c1',
                withProposal: true,
                appliedPlanId: 'plan-2',
              ),
            ],
          ),
        );

        expect(find.text('Plan updated'), findsOneWidget);
        expect(find.textContaining('Plan updated to'), findsNothing);
        expect(find.text('View plan'), findsOneWidget);
      },
    );

    testWidgets('an outdated proposal shows the muted note', (tester) async {
      await pumpCoach(
        tester,
        state: CoachChatState(messages: [userMessage, otherPlanMessage]),
      );

      expect(
        find.text('Your plan has changed since this suggestion.'),
        findsOneWidget,
      );
      expect(find.text('Review change'), findsNothing);
    });

    testWidgets('a proposal for a day the plan no longer has is outdated', (
      tester,
    ) async {
      await pumpCoach(
        tester,
        plan: withoutDayTwo,
        state: CoachChatState(messages: [userMessage, proposalMessage]),
      );

      expect(
        find.text('Your plan has changed since this suggestion.'),
        findsOneWidget,
      );
      expect(find.text('Review change'), findsNothing);
    });

    testWidgets('with no plan the status shows above the generate button', (
      tester,
    ) async {
      await pumpCoach(
        tester,
        noPlan: true,
        state: CoachChatState(messages: [userMessage, otherPlanMessage]),
      );

      final note = find.text('Your plan has changed since this suggestion.');
      final generate = find.text('Generate my plan');
      expect(note, findsOneWidget);
      expect(generate, findsOneWidget);
      expect(
        tester.getTopLeft(note).dy,
        lessThan(tester.getTopLeft(generate).dy),
      );
    });

    testWidgets('autoReviewMessageId opens the sheet once', (tester) async {
      final fake = await pumpCoach(
        tester,
        state: CoachChatState(
          messages: [userMessage, proposalMessage],
          autoReviewMessageId: 'c1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReviewChangeSheet), findsOneWidget);
      expect(fake.clearAutoReviewCalls, 1);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(ReviewChangeSheet), findsNothing);

      fake.emit(
        CoachChatState(
          messages: [userMessage, proposalMessage],
          autoReviewMessageId: 'c1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReviewChangeSheet), findsNothing);
      expect(fake.clearAutoReviewCalls, 1);
    });

    testWidgets('autoReviewMessageId waits while the page is hidden', (
      tester,
    ) async {
      final fake = await pumpCoach(
        tester,
        tickers: false,
        state: CoachChatState(
          messages: [userMessage, proposalMessage],
          autoReviewMessageId: 'c1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReviewChangeSheet), findsNothing);
      expect(fake.clearAutoReviewCalls, 0);
    });

    testWidgets('autoReviewMessageId on an outdated proposal opens nothing', (
      tester,
    ) async {
      final fake = await pumpCoach(
        tester,
        state: CoachChatState(
          messages: [userMessage, otherPlanMessage],
          autoReviewMessageId: 'c1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReviewChangeSheet), findsNothing);
      expect(fake.clearAutoReviewCalls, 1);
    });
  });

  group('changing the model after a failed reply', () {
    const failed = CoachChatState(
      messages: [],
      reply: CoachReplyFailed(
        text: '',
        error: CoachReplyFailure(),
        pendingText: 'How often should I train?',
      ),
    );

    Future<(FakeCoachChatController, FakeProfileController)> pumpFailed(
      WidgetTester tester, {
      CoachChatState state = failed,
      FakeProfileController? profile,
    }) async {
      final profileController =
          profile ?? FakeProfileController(sampleProfile());
      final fake = await pumpCoach(
        tester,
        state: state,
        profileController: profileController,
      );
      return (fake, profileController);
    }

    testWidgets('a failed reply offers Change model', (tester) async {
      await pumpFailed(tester);

      expect(
        find.text("The coach couldn't finish. Try again or change the model."),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Change model'), findsOneWidget);
      for (final label in ['Try again', 'Change model']) {
        expect(
          tester.getSize(find.widgetWithText(TextButton, label)).height,
          greaterThanOrEqualTo(kMinInteractiveDimension),
        );
      }
    });

    testWidgets('a network failure offers only Try again', (tester) async {
      await pumpFailed(
        tester,
        state: const CoachChatState(
          reply: CoachReplyFailed(
            text: '',
            error: NetworkFailure(),
            pendingText: 'How often should I train?',
          ),
        ),
      );

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Change model'), findsNothing);
    });

    testWidgets('choosing another model saves it and retries', (tester) async {
      final (fake, profile) = await pumpFailed(tester);
      var savedWhenRetried = -1;
      fake.onRetry = () => savedWhenRetried = profile.updatedAiModels.length;

      await tester.tap(find.text('Change model'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SelectableCard, 'Gemini 3.5 Flash-Lite'),
      );
      await tester.pumpAndSettle();

      expect(profile.updatedAiModels, [AiModel.geminiFlashLite]);
      expect(fake.retryCalls, 1);
      expect(savedWhenRetried, 1);
    });

    testWidgets('closing the sheet does nothing', (tester) async {
      final (fake, profile) = await pumpFailed(tester);

      await tester.tap(find.text('Change model'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(SelectableCard), findsNothing);
      expect(profile.updatedAiModels, isEmpty);
      expect(fake.retryCalls, 0);
    });

    testWidgets('choosing the current model does nothing', (tester) async {
      final (fake, profile) = await pumpFailed(tester);

      await tester.tap(find.text('Change model'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SelectableCard, 'Gemini 3.8 Flash'));
      await tester.pumpAndSettle();

      expect(profile.updatedAiModels, isEmpty);
      expect(fake.retryCalls, 0);
    });

    testWidgets('a failed save shows the message and does not retry', (
      tester,
    ) async {
      final (fake, profile) = await pumpFailed(tester);
      profile.aiModelError = const NetworkFailure();

      await tester.tap(find.text('Change model'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SelectableCard, 'Gemini 3.5 Flash-Lite'),
      );
      await tester.pumpAndSettle();

      expect(find.text(const NetworkFailure().message), findsOneWidget);
      expect(fake.retryCalls, 0);
    });

    testWidgets('Change model is hidden when the profile is not loaded', (
      tester,
    ) async {
      await pumpFailed(tester, profile: FakeProfileController(null));

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Change model'), findsNothing);
    });
  });
}
