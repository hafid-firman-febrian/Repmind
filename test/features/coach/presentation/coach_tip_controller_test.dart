import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/time/clock_provider.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/coach/data/repositories/coach_repository.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_tip_controller.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';

import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockCoachRepository repository;
  late MockPlanRepository planRepository;

  setUp(() {
    repository = MockCoachRepository();
    planRepository = MockPlanRepository();
    when(
      () => planRepository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => samplePlan());
  });

  ProviderContainer createContainer({String? userId = 'user-1'}) {
    final container = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        coachRepositoryProvider.overrideWithValue(repository),
        planRepositoryProvider.overrideWithValue(planRepository),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 5, 9)),
      ],
      retry: (_, _) => null,
    );
    container.listen(coachTipControllerProvider, (_, _) {});
    return container;
  }

  test('reads the saved tip without generating', () async {
    when(
      () => repository.fetchTip(planId: 'plan-1', date: '2026-11-05'),
    ).thenAnswer((_) async => 'Saved tip');
    final container = createContainer();

    expect(
      await container.read(coachTipControllerProvider.future),
      'Saved tip',
    );
    verifyNever(
      () => repository.generateTip(
        date: any(named: 'date'),
        weekday: any(named: 'weekday'),
      ),
    );
  });

  test('generates when there is no saved tip', () async {
    when(
      () => repository.fetchTip(planId: 'plan-1', date: '2026-11-05'),
    ).thenAnswer((_) async => null);
    when(
      () => repository.generateTip(date: '2026-11-05', weekday: 4),
    ).thenAnswer((_) async => 'Fresh tip');
    final container = createContainer();

    expect(
      await container.read(coachTipControllerProvider.future),
      'Fresh tip',
    );
    verify(
      () => repository.generateTip(date: '2026-11-05', weekday: 4),
    ).called(1);
  });

  test('no plan is null', () async {
    when(
      () => planRepository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => null);
    final container = createContainer();

    expect(await container.read(coachTipControllerProvider.future), isNull);
    verifyZeroInteractions(repository);
  });

  test('any failure is null', () async {
    when(
      () => repository.fetchTip(
        planId: any(named: 'planId'),
        date: any(named: 'date'),
      ),
    ).thenThrow(const NetworkFailure());
    final container = createContainer();

    expect(await container.read(coachTipControllerProvider.future), isNull);
    expect(
      container.read(coachTipControllerProvider),
      isA<AsyncData<String?>>(),
    );
  });

  test('a generation failure is null', () async {
    when(
      () => repository.fetchTip(
        planId: any(named: 'planId'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => repository.generateTip(
        date: any(named: 'date'),
        weekday: any(named: 'weekday'),
      ),
    ).thenThrow(const PlanGenerationFailure());
    final container = createContainer();

    expect(await container.read(coachTipControllerProvider.future), isNull);
  });

  test('a plan load failure is null', () async {
    when(
      () => planRepository.fetchActivePlan('user-1'),
    ).thenThrow(const NetworkFailure());
    final container = createContainer();

    expect(await container.read(coachTipControllerProvider.future), isNull);
    verifyZeroInteractions(repository);
  });

  test('a repository that cannot be read is null', () async {
    final container = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        coachRepositoryProvider.overrideWith((ref) => throw StateError('no')),
        planRepositoryProvider.overrideWithValue(planRepository),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 5, 9)),
      ],
      retry: (_, _) => null,
    );
    container.listen(coachTipControllerProvider, (_, _) {});

    expect(await container.read(coachTipControllerProvider.future), isNull);
  });

  test('a new plan loads a new tip', () async {
    when(
      () => repository.fetchTip(planId: 'plan-1', date: '2026-11-05'),
    ).thenAnswer((_) async => 'Tip for plan 1');
    when(
      () => repository.fetchTip(planId: 'plan-2', date: '2026-11-05'),
    ).thenAnswer((_) async => 'Tip for plan 2');
    final container = createContainer();
    container.listen(activePlanControllerProvider, (_, _) {});

    expect(
      await container.read(coachTipControllerProvider.future),
      'Tip for plan 1',
    );

    when(
      () => planRepository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => samplePlan(version: 2));
    await container.refresh(activePlanControllerProvider.future);

    expect(
      await container.read(coachTipControllerProvider.future),
      'Tip for plan 2',
    );
  });
}
