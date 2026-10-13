import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
import 'package:repmind/features/plan/presentation/pages/generating_page.dart';
import 'package:repmind/features/plan/presentation/states/plan_generation_state.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_plan_generation_controller.dart';
import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/pump_router.dart';

void main() {
  late FakePlanGenerationController generation;

  Future<void> pumpGenerating(
    WidgetTester tester,
    PlanGenerationState state,
  ) async {
    generation = FakePlanGenerationController(state);
    final router = await pumpRouter(
      tester,
      initialLocation: AppRoutes.plan,
      overrides: [
        planGenerationControllerProvider.overrideWith(() => generation),
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile()),
        ),
      ],
      routes: [
        GoRoute(
          path: AppRoutes.plan,
          builder: (_, _) => const Text('plan page'),
        ),
        GoRoute(
          path: AppRoutes.generating,
          builder: (_, _) => const GeneratingPage(),
        ),
      ],
    );
    unawaited(router.push(AppRoutes.generating));
    await tester.pump();
    await tester.pump();
  }

  Future<void> settleNavigation(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  PlanGenerationState stateOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  ).read(planGenerationControllerProvider);

  testWidgets('while building shows the title, a status and the context', (
    tester,
  ) async {
    await pumpGenerating(tester, const PlanGenerationRunning());

    expect(find.text('BUILDING YOUR PLAN'), findsOneWidget);
    expect(find.text('Reading your profile'), findsOneWidget);
    expect(
      find.text('4 days · Build muscle · Gemini 3.8 Flash'),
      findsOneWidget,
    );

    await tester.pump(GeneratingPage.statusInterval);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Reading your profile'), findsNothing);
    expect(find.text('Picking exercises for your equipment'), findsOneWidget);
  });

  testWidgets('an adjustment is titled as such', (tester) async {
    await pumpGenerating(
      tester,
      const PlanGenerationRunning(instruction: 'More core work'),
    );

    expect(find.text('ADJUSTING YOUR PLAN'), findsOneWidget);
  });

  testWidgets('success opens the plan and resets the flow', (tester) async {
    await pumpGenerating(tester, const PlanGenerationRunning());

    generation.emit(const PlanGenerationSucceeded());
    await settleNavigation(tester);

    expect(find.byType(GeneratingPage), findsNothing);
    expect(find.text('plan page'), findsOneWidget);
    expect(stateOf(tester), isA<PlanGenerationIdle>());
  });

  testWidgets('a failure explains it and offers to try again', (tester) async {
    await pumpGenerating(
      tester,
      const PlanGenerationFailed(PlanGenerationFailure()),
    );

    expect(find.text(const PlanGenerationFailure().message), findsOneWidget);
    await tester.tap(find.text('Try again'));

    expect(generation.retryCalls, 1);
  });

  testWidgets('Back from a failure returns to the previous screen', (
    tester,
  ) async {
    await pumpGenerating(tester, const PlanGenerationFailed(NetworkFailure()));

    await tester.tap(find.text('Back'));
    await settleNavigation(tester);

    expect(find.byType(GeneratingPage), findsNothing);
    expect(stateOf(tester), isA<PlanGenerationIdle>());
  });

  testWidgets('opening the screen with nothing running returns to the plan', (
    tester,
  ) async {
    await pumpGenerating(tester, const PlanGenerationIdle());
    await settleNavigation(tester);

    expect(find.byType(GeneratingPage), findsNothing);
    expect(find.text('plan page'), findsOneWidget);
  });
}
