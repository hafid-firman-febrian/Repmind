import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapToAppException', () {
    test('wrong email or password', () {
      expect(
        mapToAppException(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        ),
        isA<InvalidCredentials>(),
      );
    });

    test('email already registered', () {
      for (final code in ['user_already_exists', 'email_exists']) {
        expect(
          mapToAppException(AuthException('exists', code: code)),
          isA<EmailAlreadyRegistered>(),
        );
      }
    });

    test('weak password', () {
      expect(
        mapToAppException(const AuthException('weak', code: 'weak_password')),
        isA<WeakPassword>(),
      );
    });

    test('network problems', () {
      expect(
        mapToAppException(const SocketException('offline')),
        isA<NetworkFailure>(),
      );
      expect(
        mapToAppException(TimeoutException('slow')),
        isA<NetworkFailure>(),
      );
      expect(
        mapToAppException(AuthRetryableFetchException()),
        isA<NetworkFailure>(),
      );
    });

    test('Google dialog closed by the user', () {
      expect(
        mapToAppException(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        ),
        isA<SignInCancelled>(),
      );
    });

    test('storage upload failure', () {
      expect(
        mapToAppException(const StorageException('boom')),
        isA<StorageFailure>(),
      );
    });

    test('edge function failures', () {
      expect(
        mapToAppException(const FunctionsHttpException(status: 502)),
        isA<PlanGenerationFailure>(),
      );
      expect(
        mapToAppException(const FunctionsHttpException(status: 500)),
        isA<UnknownFailure>(),
      );
      expect(
        mapToAppException(const FunctionsHttpException(status: 409)),
        isA<UnknownFailure>(),
      );
      expect(
        mapToAppException(const FunctionsFetchException(details: 'offline')),
        isA<NetworkFailure>(),
      );
    });

    test('anything else is unknown', () {
      expect(mapToAppException(StateError('bug')), isA<UnknownFailure>());
      expect(
        mapToAppException(const PostgrestException(message: 'db down')),
        isA<UnknownFailure>(),
      );
    });

    test('app exceptions pass through unchanged', () {
      const error = WeakPassword();
      expect(mapToAppException(error), same(error));
    });
  });

  test('runGuarded rethrows mapped exceptions', () async {
    await expectLater(
      runGuarded<void>(() async => throw const SocketException('offline')),
      throwsA(isA<NetworkFailure>()),
    );
  });

  group('guardStream', () {
    test('passes events through unchanged', () async {
      final events = await guardStream(Stream.fromIterable([1, 2, 3])).toList();

      expect(events, [1, 2, 3]);
    });

    test('maps a stream error to an app exception', () async {
      final stream = guardStream(
        Stream<int>.error(const SocketException('offline')),
      );

      await expectLater(stream, emitsError(isA<NetworkFailure>()));
    });

    test('uses the custom mapper when given', () async {
      final stream = guardStream(
        Stream<int>.error(StateError('bug')),
        map: (_) => const WeakPassword(),
      );

      await expectLater(stream, emitsError(isA<WeakPassword>()));
    });

    test('keeps the original stack trace', () async {
      final trace = StackTrace.fromString('original-trace');
      final stream = guardStream(
        Stream<int>.error(const SocketException('offline'), trace),
      );

      Object? caught;
      StackTrace? caughtTrace;
      try {
        await stream.drain<void>();
      } catch (error, stackTrace) {
        caught = error;
        caughtTrace = stackTrace;
      }

      expect(caught, isA<NetworkFailure>());
      expect(caughtTrace.toString(), contains('original-trace'));
    });

    test('delivers events before the error', () async {
      Stream<int> source() async* {
        yield 1;
        throw const SocketException('offline');
      }

      final stream = guardStream(source());

      await expectLater(
        stream,
        emitsInOrder([1, emitsError(isA<NetworkFailure>())]),
      );
    });
  });
}
