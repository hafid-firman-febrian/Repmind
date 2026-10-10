import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) =>
      _run((repository) => repository.signIn(email: email, password: password));

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(
    (repository) =>
        repository.signUp(name: name, email: email, password: password),
  );

  Future<void> signInWithGoogle() =>
      _run((repository) => repository.signInWithGoogle());

  Future<void> signOut() => _run((repository) => repository.signOut());

  Future<void> _run(
    Future<void> Function(AuthRepository repository) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => action(ref.read(authRepositoryProvider)),
    );
    if (ref.mounted) state = result;
  }
}

String? visibleAuthError(AsyncValue<void> state) {
  final error = state.error;
  if (error == null) return null;
  final exception = mapToAppException(error);
  return _isFormError(exception) ? exception.message : null;
}

String? authSnackBarError(AsyncValue<void> state) {
  final error = state.error;
  if (error == null) return null;
  final exception = mapToAppException(error);
  if (exception is SignInCancelled || _isFormError(exception)) return null;
  return exception.message;
}

bool _isFormError(AppException exception) => switch (exception) {
  InvalidCredentials() || EmailAlreadyRegistered() || WeakPassword() => true,
  _ => false,
};
