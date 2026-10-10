import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_controller.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAuthRepository();
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
    container.listen(authControllerProvider, (_, _) {});
  });

  test('signIn ends in data on success', () async {
    when(
      () => repository.signIn(email: 'a@b.co', password: 'secret123'),
    ).thenAnswer((_) async {});

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.co', password: 'secret123');

    expect(container.read(authControllerProvider), isA<AsyncData<void>>());
  });

  test('signIn exposes the AppException on failure', () async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const InvalidCredentials());

    await container
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.co', password: 'wrong-pass');

    expect(
      container.read(authControllerProvider).error,
      isA<InvalidCredentials>(),
    );
  });

  test('a second tap while signing in is ignored', () async {
    final pending = Completer<void>();
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => pending.future);
    final notifier = container.read(authControllerProvider.notifier);

    final first = notifier.signIn(email: 'a@b.co', password: 'secret123');
    await notifier.signIn(email: 'a@b.co', password: 'secret123');
    pending.complete();
    await first;

    verify(
      () => repository.signIn(email: 'a@b.co', password: 'secret123'),
    ).called(1);
  });

  test('signOut delegates to the repository', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});

    await container.read(authControllerProvider.notifier).signOut();

    verify(() => repository.signOut()).called(1);
  });

  test('visibleAuthError hides a cancelled Google dialog', () {
    expect(
      visibleAuthError(
        const AsyncError<void>(SignInCancelled(), StackTrace.empty),
      ),
      isNull,
    );
    expect(
      visibleAuthError(
        const AsyncError<void>(InvalidCredentials(), StackTrace.empty),
      ),
      const InvalidCredentials().message,
    );
    expect(visibleAuthError(const AsyncData<void>(null)), isNull);
  });

  test('visibleAuthError leaves non-form errors to the snack bar', () {
    expect(
      visibleAuthError(
        const AsyncError<void>(NetworkFailure(), StackTrace.empty),
      ),
      isNull,
    );
  });

  test('authSnackBarError shows non-form errors only', () {
    expect(
      authSnackBarError(
        const AsyncError<void>(NetworkFailure(), StackTrace.empty),
      ),
      const NetworkFailure().message,
    );
    expect(
      authSnackBarError(
        const AsyncError<void>(SignInCancelled(), StackTrace.empty),
      ),
      isNull,
    );
    expect(
      authSnackBarError(
        const AsyncError<void>(InvalidCredentials(), StackTrace.empty),
      ),
      isNull,
    );
    expect(authSnackBarError(const AsyncData<void>(null)), isNull);
  });
}
