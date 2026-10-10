import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/auth/presentation/pages/sign_in_page.dart';
import 'package:repmind/features/auth/presentation/pages/sign_up_page.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  testWidgets('Sign in validates before calling the repository', (
    tester,
  ) async {
    await pumpPage(
      tester,
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('Sign up rejects short passwords', (tester) async {
    await pumpPage(
      tester,
      const SignUpPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(find.byKey(const ValueKey('sign-up-name')), 'Alex');
    await tester.enterText(
      find.byKey(const ValueKey('sign-up-email')),
      'alex@mail.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-up-password')),
      'short',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    verifyNever(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('Sign in shows wrong-credential errors under the form', (
    tester,
  ) async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const InvalidCredentials());
    await pumpPage(
      tester,
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')),
      'alex@mail.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'wrong-pass',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Sign in shows network errors in a snack bar, not the form', (
    tester,
  ) async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const NetworkFailure());
    await pumpPage(
      tester,
      const SignInPage(),
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );

    await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')),
      'alex@mail.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'secret123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump();

    final message = const NetworkFailure().message;
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.text(message)),
      findsOneWidget,
    );
    expect(find.text(message), findsOneWidget);
  });
}
