import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockPlanRemoteDataSource remote;
  late PlanRepository repository;

  setUp(() {
    remote = MockPlanRemoteDataSource();
    repository = PlanRepository(remote);
  });

  test('fetchActivePlan maps the nested row to a WorkoutPlan', () async {
    when(
      () => remote.fetchActivePlan('user-1'),
    ).thenAnswer((_) async => workoutPlanRow(version: 2));

    final plan = await repository.fetchActivePlan('user-1');

    expect(plan!.version, 2);
    expect(plan.days, hasLength(4));
  });

  test('fetchActivePlan is null when there is no active plan', () async {
    when(() => remote.fetchActivePlan('user-1')).thenAnswer((_) async => null);

    expect(await repository.fetchActivePlan('user-1'), isNull);
  });

  test('generatePlan forwards the instruction and returns the id', () async {
    when(
      () => remote.generatePlan(instruction: 'More core work'),
    ).thenAnswer((_) async => 'plan-2');

    expect(
      await repository.generatePlan(instruction: 'More core work'),
      'plan-2',
    );
  });

  test('errors are mapped to AppException', () async {
    when(
      () => remote.generatePlan(instruction: any(named: 'instruction')),
    ).thenThrow(const FunctionsHttpException(status: 502));
    when(
      () => remote.fetchActivePlan(any()),
    ).thenThrow(const SocketException('offline'));

    await expectLater(
      repository.generatePlan(),
      throwsA(isA<PlanGenerationFailure>()),
    );
    await expectLater(
      repository.fetchActivePlan('user-1'),
      throwsA(isA<NetworkFailure>()),
    );
  });
}
