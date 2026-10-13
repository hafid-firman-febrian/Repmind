import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';
import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';
import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
import 'package:repmind/features/plan/presentation/states/plan_generation_state.dart';

import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockPlanRepository repository;

  setUp(() => repository = MockPlanRepository());

  ProviderContainer createContainer() {
    final container = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        planRepositoryProvider.overrideWithValue(repository),
      ],
      retry: (_, _) => null,
    );
    container.listen(activePlanControllerProvider, (_, _) {});
    container.listen(planGenerationControllerProvider, (_, _) {});
    return container;
  }

  void answerPlans(List<WorkoutPlan?> plans) {
    when(
      () => repository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => plans.removeAt(0));
  }

  test('generate runs, refreshes the active plan and succeeds', () async {
    answerPlans([null, samplePlan()]);
    when(
      () => repository.generatePlan(instruction: null),
    ).thenAnswer((_) async => 'plan-1');
    final container = createContainer();
    await container.read(activePlanControllerProvider.future);
    final states = <PlanGenerationState>[];
    container.listen(
      planGenerationControllerProvider,
      (_, next) => states.add(next),
    );

    await container.read(planGenerationControllerProvider.notifier).generate();

    expect(states.first, isA<PlanGenerationRunning>());
    expect(
      container.read(planGenerationControllerProvider),
      isA<PlanGenerationSucceeded>(),
    );
    expect(container.read(activePlanControllerProvider).value!.version, 1);
  });

  test('a failure keeps the error and the instruction', () async {
    answerPlans([samplePlan()]);
    when(
      () => repository.generatePlan(instruction: 'More core work'),
    ).thenThrow(const PlanGenerationFailure());
    final container = createContainer();

    await container
        .read(planGenerationControllerProvider.notifier)
        .generate(instruction: 'More core work');

    final state = container.read(planGenerationControllerProvider);
    expect(state, isA<PlanGenerationFailed>());
    state as PlanGenerationFailed;
    expect(state.error, isA<PlanGenerationFailure>());
    expect(state.instruction, 'More core work');
  });

  test('a second generate while one is running is ignored', () async {
    answerPlans([null, samplePlan()]);
    final pending = Completer<String>();
    when(
      () => repository.generatePlan(instruction: null),
    ).thenAnswer((_) => pending.future);
    final container = createContainer();
    final notifier = container.read(planGenerationControllerProvider.notifier);

    final first = notifier.generate();
    await notifier.generate();
    pending.complete('plan-1');
    await first;

    verify(() => repository.generatePlan(instruction: null)).called(1);
  });

  test('retry repeats the last instruction', () async {
    answerPlans([samplePlan(), samplePlan(version: 2)]);
    var calls = 0;
    when(
      () => repository.generatePlan(instruction: 'More core work'),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw const PlanGenerationFailure();
      return 'plan-2';
    });
    final container = createContainer();
    final notifier = container.read(planGenerationControllerProvider.notifier);
    await notifier.generate(instruction: 'More core work');

    await notifier.retry();

    expect(calls, 2);
    expect(
      container.read(planGenerationControllerProvider),
      isA<PlanGenerationSucceeded>(),
    );
  });

  test('a saved plan that fails to reload still counts as success', () async {
    var loads = 0;
    when(() => repository.fetchActivePlan('user-1')).thenAnswer((_) async {
      loads++;
      if (loads == 1) return samplePlan();
      throw const NetworkFailure();
    });
    when(
      () => repository.generatePlan(instruction: 'More core work'),
    ).thenAnswer((_) async => 'plan-2');
    final container = createContainer();
    await container.read(activePlanControllerProvider.future);

    await container
        .read(planGenerationControllerProvider.notifier)
        .generate(instruction: 'More core work');

    expect(
      container.read(planGenerationControllerProvider),
      isA<PlanGenerationSucceeded>(),
    );
    verify(
      () => repository.generatePlan(instruction: 'More core work'),
    ).called(1);
  });

  test('reset returns to idle', () async {
    answerPlans([samplePlan()]);
    when(
      () => repository.generatePlan(instruction: null),
    ).thenThrow(const PlanGenerationFailure());
    final container = createContainer();
    final notifier = container.read(planGenerationControllerProvider.notifier);
    await notifier.generate();

    notifier.reset();

    expect(
      container.read(planGenerationControllerProvider),
      isA<PlanGenerationIdle>(),
    );
  });
}
