import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/core/theme/repmind_theme.dart';
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

  testWidgets('a retry shows one snack bar per failure, none while pending', (
    tester,
  ) async {
    final secondAttempt = Completer<void>();
    var attempts = 0;
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) {
      attempts++;
      return attempts == 1
          ? Future.error(const NetworkFailure())
          : secondAttempt.future;
    });
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
    final message = const NetworkFailure().message;

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    await tester.pump();
    expect(find.text(message), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text(message), findsNothing);

    secondAttempt.completeError(const NetworkFailure());
    await tester.pump();
    await tester.pump();
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('the credential error is hidden while a retry is in flight', (
    tester,
  ) async {
    final secondAttempt = Completer<void>();
    var attempts = 0;
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) {
      attempts++;
      return attempts == 1
          ? Future.error(const InvalidCredentials())
          : secondAttempt.future;
    });
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

    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Incorrect email or password.'), findsNothing);

    secondAttempt.complete();
    await tester.pump();
  });

  testWidgets('switching to sign up clears the sign-in credential error', (
    tester,
  ) async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const InvalidCredentials());
    final router = GoRouter(
      initialLocation: AppRoutes.signIn,
      routes: [
        GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
        GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        retry: (_, _) => null,
        child: MaterialApp.router(
          theme: buildRepmindTheme(),
          routerConfig: router,
        ),
      ),
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

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    expect(find.byType(SignUpPage), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsNothing);
  });

  testWidgets('the keyboard Done key submits the sign-in form', (tester) async {
    when(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
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

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(
      () => repository.signIn(email: 'alex@mail.com', password: 'secret123'),
    ).called(1);
  });

  testWidgets('the keyboard Done key submits the sign-up form', (tester) async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
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
      'secret123',
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(
      () => repository.signUp(
        name: 'Alex',
        email: 'alex@mail.com',
        password: 'secret123',
      ),
    ).called(1);
  });
}
