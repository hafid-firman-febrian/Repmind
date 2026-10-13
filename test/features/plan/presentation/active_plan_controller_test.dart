import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';

import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/mocks.dart';

class TestUserId extends Notifier<String?> {
  TestUserId(this._initial);

  final String? _initial;

  @override
  String? build() => _initial;

  void signInAs(String? userId) => state = userId;
}

final testUserIdProvider = NotifierProvider<TestUserId, String?>(
  () => TestUserId(null),
);

void main() {
  late MockPlanRepository repository;

  setUp(() => repository = MockPlanRepository());

  ProviderContainer containerFor(String? userId) {
    final container = ProviderContainer.test(
      overrides: [
        testUserIdProvider.overrideWith(() => TestUserId(userId)),
        currentUserIdProvider.overrideWith(
          (ref) => ref.watch(testUserIdProvider),
        ),
        planRepositoryProvider.overrideWithValue(repository),
      ],
      retry: (_, _) => null,
    );
    container.listen(activePlanControllerProvider, (_, _) {});
    return container;
  }

  test('loads the active plan of the signed-in user', () async {
    final plan = samplePlan();
    when(
      () => repository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => plan);

    final container = containerFor('user-1');

    expect(
      await container.read(activePlanControllerProvider.future),
      same(plan),
    );
  });

  test('is null when nobody is signed in', () async {
    final container = containerFor(null);

    expect(await container.read(activePlanControllerProvider.future), isNull);
    verifyNever(() => repository.fetchActivePlan(any()));
  });

  test('reloads when the signed-in user changes', () async {
    when(
      () => repository.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => samplePlan());
    final other = samplePlan(version: 5);
    when(
      () => repository.fetchActivePlan('user-2'),
    ).thenAnswer((_) async => other);
    final container = containerFor('user-1');
    await container.read(activePlanControllerProvider.future);

    container.read(testUserIdProvider.notifier).signInAs('user-2');

    expect(
      await container.read(activePlanControllerProvider.future),
      same(other),
    );
  });
}
