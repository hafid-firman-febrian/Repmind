import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/data/data_sources/google_auth_data_source.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/auth/domain/models/auth_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockGoogleAuthDataSource google;
  late AuthRepository repository;

  setUpAll(() => registerFallbackValue(OAuthProvider.google));

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    google = MockGoogleAuthDataSource();
    when(() => client.auth).thenReturn(auth);
    repository = AuthRepository(client, google);
  });

  test(
    'signUp trims and lowercases the email and sends the name as metadata',
    () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      await repository.signUp(
        name: ' Alex ',
        email: ' Alex@Mail.COM ',
        password: 'secret123',
      );

      final captured = verify(
        () => auth.signUp(
          email: captureAny(named: 'email'),
          password: 'secret123',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect(captured, [
        'alex@mail.com',
        {'full_name': 'Alex'},
      ]);
    },
  );

  test('signIn normalizes the email', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await repository.signIn(email: ' Alex@Mail.com', password: 'secret123');

    verify(
      () => auth.signInWithPassword(
        email: 'alex@mail.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  test('signIn reports wrong credentials as InvalidCredentials', () async {
    when(
      () => auth.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      ),
    );

    await expectLater(
      repository.signIn(email: 'alex@mail.com', password: 'wrong-pass'),
      throwsA(isA<InvalidCredentials>()),
    );
  });

  test('signInWithGoogle exchanges the Google tokens with Supabase', () async {
    when(() => google.signIn()).thenAnswer(
      (_) async =>
          const GoogleTokens(idToken: 'id-token', accessToken: 'access-token'),
    );
    when(
      () => auth.signInWithIdToken(
        provider: any(named: 'provider'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
      ),
    ).thenAnswer((_) async => AuthResponse());

    await repository.signInWithGoogle();

    verify(
      () => auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: 'id-token',
        accessToken: 'access-token',
      ),
    ).called(1);
  });

  test('signInWithGoogle reports a closed dialog as SignInCancelled', () async {
    when(() => google.signIn()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    await expectLater(
      repository.signInWithGoogle(),
      throwsA(isA<SignInCancelled>()),
    );
    verifyNever(
      () => auth.signInWithIdToken(
        provider: any(named: 'provider'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
      ),
    );
  });

  test('signOut succeeds even if the Google sign-out fails', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => google.signOut()).thenThrow(Exception('not configured'));

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
    verify(() => google.signOut()).called(1);
  });

  test(
    'signOut still signs out of Google when Supabase sign-out fails',
    () async {
      when(() => auth.signOut()).thenThrow(AuthRetryableFetchException());
      when(() => google.signOut()).thenAnswer((_) async {});

      await expectLater(repository.signOut(), throwsA(isA<NetworkFailure>()));

      verify(() => google.signOut()).called(1);
    },
  );

  test('authStatusChanges maps sessions to AuthStatus', () {
    when(() => auth.onAuthStateChange).thenAnswer(
      (_) => Stream.fromIterable([
        const AuthState(AuthChangeEvent.initialSession, null),
        AuthState(AuthChangeEvent.signedIn, MockSession()),
      ]),
    );

    expect(
      repository.authStatusChanges(),
      emitsInOrder([AuthStatus.signedOut, AuthStatus.signedIn]),
    );
  });

  test('authStatusChanges maps stream errors to AppException', () {
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => Stream<AuthState>.error(AuthRetryableFetchException()));

    expect(repository.authStatusChanges(), emitsError(isA<NetworkFailure>()));
  });

  test('authStatusChanges maps unknown stream errors to UnknownFailure', () {
    when(
      () => auth.onAuthStateChange,
    ).thenAnswer((_) => Stream<AuthState>.error(const AuthException('boom')));

    expect(repository.authStatusChanges(), emitsError(isA<UnknownFailure>()));
  });
}
