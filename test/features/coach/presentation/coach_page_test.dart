import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/features/coach/application/services/coach_rules.dart';
import 'package:repmind/features/coach/domain/models/chat_message_model.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_chat_controller.dart';
import 'package:repmind/features/coach/presentation/pages/coach_page.dart';
import 'package:repmind/features/coach/presentation/states/coach_chat_state.dart';
import 'package:repmind/features/coach/presentation/widgets/coach_bubbles.dart';
import 'package:repmind/features/coach/presentation/widgets/coach_input_bar.dart';
import 'package:repmind/features/coach/presentation/widgets/streaming_dots.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';
import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
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
  }) async {
    useTallScreen(tester);
    final fake = controller ?? FakeCoachChatController(state);
    final generation = FakePlanGenerationController();
    await pumpRouter(
      tester,
      initialLocation: AppRoutes.coach,
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(profile ?? sampleProfile()),
        ),
        activePlanControllerProvider.overrideWith(
          () => FakeActivePlanController(noPlan ? null : plan ?? samplePlan()),
        ),
        planGenerationControllerProvider.overrideWith(() => generation),
        coachChatControllerProvider.overrideWith(() => fake),
      ],
      routes: [
        GoRoute(path: AppRoutes.coach, builder: (_, _) => const CoachPage()),
        GoRoute(
          path: AppRoutes.generating,
          builder: (_, _) => const Text('generating'),
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
}
