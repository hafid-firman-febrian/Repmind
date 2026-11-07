import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/core/time/clock_provider.dart';
import 'package:repmind/core/widgets/coach_tip_card.dart';
import 'package:repmind/features/coach/data/repositories/coach_repository.dart';
import 'package:repmind/features/home/application/services/greeting.dart';
import 'package:repmind/features/home/presentation/pages/home_page.dart';
import 'package:repmind/features/home/presentation/widgets/this_week_card.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';
import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_active_plan_controller.dart';
import '../../../fakes/fake_plan_generation_controller.dart';
import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/plan_fixtures.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/pump_router.dart';

void main() {
  final tuesday = DateTime(2026, 10, 13, 9);

  Future<void> pumpHome(
    WidgetTester tester, {
    WorkoutPlan? plan,
    DateTime? now,
    Profile? profile,
    bool tall = true,
    MockCoachRepository? coach,
  }) async {
    if (tall) useTallScreen(tester);
    await pumpRouter(
      tester,
      initialLocation: AppRoutes.home,
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(profile ?? sampleProfile()),
        ),
        activePlanControllerProvider.overrideWith(
          () => FakeActivePlanController(plan),
        ),
        planGenerationControllerProvider.overrideWith(
          () => FakePlanGenerationController(),
        ),
        clockProvider.overrideWithValue(() => now ?? tuesday),
        if (coach != null) coachRepositoryProvider.overrideWithValue(coach),
      ],
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
        GoRoute(
          path: AppRoutes.workoutDay,
          builder: (_, state) => Text('workout ${state.pathParameters['day']}'),
        ),
        GoRoute(
          path: AppRoutes.generating,
          builder: (_, _) => const Text('generating'),
        ),
        GoRoute(
          path: AppRoutes.coach,
          builder: (_, _) => const Text('coach page'),
        ),
      ],
    );
    await tester.pump();
  }

  testWidgets('greets the user and shows today\'s workout and the week', (
    tester,
  ) async {
    await pumpHome(tester, plan: samplePlan());

    expect(find.text(greetingFor(tuesday).toUpperCase()), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('AI PLAN · DAY 2 OF 4'), findsOneWidget);
    expect(find.text('UPPER BODY PUSH'), findsOneWidget);
    expect(
      find.text('6 exercises · ~45 min · Dumbbells, Bench'),
      findsOneWidget,
    );
    expect(find.text('02'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('4 workouts'), findsOneWidget);
    expect(find.bySemanticsLabel('Tuesday, workout, today'), findsOneWidget);
    expect(find.bySemanticsLabel('Wednesday, rest'), findsOneWidget);
    expect(find.text('BMI'), findsNothing);
  });

  testWidgets('on a rest day shows the next workout', (tester) async {
    await pumpHome(tester, plan: samplePlan(), now: DateTime(2026, 10, 14, 9));

    expect(find.text('AI PLAN · NEXT · THU'), findsOneWidget);
    expect(find.text('LEGS & CORE'), findsOneWidget);
    expect(find.bySemanticsLabel('Wednesday, rest, today'), findsOneWidget);
  });

  testWidgets('after the last workout of the week points to Monday', (
    tester,
  ) async {
    await pumpHome(tester, plan: samplePlan(), now: DateTime(2026, 10, 18, 9));

    expect(find.text('AI PLAN · NEXT · MON'), findsOneWidget);
    expect(find.text('LOWER BODY POWER'), findsOneWidget);
  });

  testWidgets('the play button opens the workout', (tester) async {
    await pumpHome(tester, plan: samplePlan());

    await tester.tap(find.byTooltip('Open workout'));
    await tester.pumpAndSettle();

    expect(find.text('workout 2'), findsOneWidget);
  });

  testWidgets('without a plan offers to generate one', (tester) async {
    await pumpHome(tester);

    expect(find.text('YOUR AI PLAN'), findsOneWidget);
    expect(find.text('Generate my plan'), findsOneWidget);
  });

  testWidgets('keeps a very long display name on one line', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final longName = List.filled(12, 'Maximiliano').join(' ');

    await pumpHome(
      tester,
      tall: false,
      profile: Profile.fromJson({...profileRow(), 'display_name': longName}),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(longName), findsOneWidget);
  });

  group('coach tip', () {
    late MockCoachRepository coach;

    setUp(() {
      coach = MockCoachRepository();
    });

    void stubTip(String? tip) {
      when(
        () => coach.fetchTip(
          planId: any(named: 'planId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => tip);
    }

    testWidgets('shows the tip under This week', (tester) async {
      stubTip('Slow the lowering phase.');
      await pumpHome(tester, plan: samplePlan(), coach: coach);
      await tester.pump();

      expect(find.text('Slow the lowering phase.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(CoachTipCard)).dy,
        greaterThan(tester.getBottomLeft(find.byType(ThisWeekCard)).dy),
      );
    });

    testWidgets('tapping the tip opens Coach', (tester) async {
      stubTip('Slow the lowering phase.');
      await pumpHome(tester, plan: samplePlan(), coach: coach);
      await tester.pump();

      await tester.tap(find.byType(CoachTipCard));
      await tester.pumpAndSettle();

      expect(find.text('coach page'), findsOneWidget);
    });

    testWidgets('a null tip hides the card and Home still renders', (
      tester,
    ) async {
      stubTip(null);
      when(
        () => coach.generateTip(
          date: any(named: 'date'),
          weekday: any(named: 'weekday'),
        ),
      ).thenThrow(const PlanGenerationFailure());
      await pumpHome(tester, plan: samplePlan(), coach: coach);
      await tester.pump();

      expect(find.byType(CoachTipCard), findsNothing);
      expect(find.text('Coach tip'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.text('UPPER BODY PUSH'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('no plan shows no tip', (tester) async {
      stubTip('Should not show');
      await pumpHome(tester, coach: coach);
      await tester.pump();

      expect(find.byType(CoachTipCard), findsNothing);
      expect(find.text('Generate my plan'), findsOneWidget);
      verifyZeroInteractions(coach);
    });
  });
}
