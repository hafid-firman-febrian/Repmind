import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

AppException mapToAppException(Object error) => switch (error) {
  AppException() => error,
  AuthRetryableFetchException() => const NetworkFailure(),
  AuthWeakPasswordException() => const WeakPassword(),
  AuthException(code: 'weak_password') => const WeakPassword(),
  AuthException(code: 'invalid_credentials') => const InvalidCredentials(),
  AuthException(code: 'user_already_exists' || 'email_exists') =>
    const EmailAlreadyRegistered(),
  GoogleSignInException(code: GoogleSignInExceptionCode.canceled) =>
    const SignInCancelled(),
  SocketException() || TimeoutException() => const NetworkFailure(),
  StorageException() => const StorageFailure(),
  _ => const UnknownFailure(),
};

Future<T> runGuarded<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    final mapped = mapToAppException(error);
    if (mapped is UnknownFailure) {
      log(
        'Unexpected error',
        name: 'repmind',
        error: error,
        stackTrace: stackTrace,
      );
    }
    Error.throwWithStackTrace(mapped, stackTrace);
  }
}
