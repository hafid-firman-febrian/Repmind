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
}
