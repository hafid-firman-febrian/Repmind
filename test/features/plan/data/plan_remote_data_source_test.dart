import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/plan/data/data_sources/plan_remote_data_source.dart';
import 'package:repmind/features/plan/data/repositories/plan_repository.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MockFunctionsClient functions;

  setUp(() {
    client = MockSupabaseClient();
    functions = MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    when(
      () => functions.invoke('generate-plan', body: any(named: 'body')),
    ).thenAnswer((_) => Completer<Never>().future);
  });

  test('generatePlan waits 150 seconds by default', () {
    expect(
      PlanRemoteDataSource(client).generateTimeout,
      const Duration(seconds: 150),
    );
  });

  test('a generate call that never answers ends as a network failure', () {
    final repository = PlanRepository(
      PlanRemoteDataSource(
        client,
        generateTimeout: const Duration(milliseconds: 10),
      ),
    );

    expect(repository.generatePlan(), throwsA(isA<NetworkFailure>()));
  });
}
