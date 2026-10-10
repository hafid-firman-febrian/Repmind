sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class InvalidCredentials extends AppException {
  const InvalidCredentials() : super('Incorrect email or password.');
}

final class EmailAlreadyRegistered extends AppException {
  const EmailAlreadyRegistered()
    : super(
        'An account with this email already exists. Try signing in instead.',
      );
}

final class WeakPassword extends AppException {
  const WeakPassword()
    : super('Password is too weak. Use at least 8 characters.');
}

final class SignInCancelled extends AppException {
  const SignInCancelled() : super('Sign-in was cancelled.');
}

final class NetworkFailure extends AppException {
  const NetworkFailure()
    : super('No internet connection. Check your network and try again.');
}

final class StorageFailure extends AppException {
  const StorageFailure()
    : super('Could not upload the photo. Please try again.');
}

final class UnknownFailure extends AppException {
  const UnknownFailure() : super('Something went wrong. Please try again.');
}
