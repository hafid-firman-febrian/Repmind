import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/models/auth_status.dart';
import '../data_sources/google_auth_data_source.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  AuthRepository(this._client, this._google);

  final SupabaseClient _client;
  final GoogleAuthDataSource _google;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthStatus> authStatusChanges() => _auth.onAuthStateChange.map(
    (state) =>
        state.session == null ? AuthStatus.signedOut : AuthStatus.signedIn,
  );

  String? get currentUserId => _auth.currentUser?.id;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => runGuarded(
    () => _auth.signUp(
      email: _normalizeEmail(email),
      password: password,
      data: {'full_name': name.trim()},
    ),
  );

  Future<void> signIn({required String email, required String password}) =>
      runGuarded(
        () => _auth.signInWithPassword(
          email: _normalizeEmail(email),
          password: password,
        ),
      );

  Future<void> signInWithGoogle() => runGuarded(() async {
    final tokens = await _google.signIn();
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: tokens.idToken,
      accessToken: tokens.accessToken,
    );
  });

  Future<void> signOut() => runGuarded(() async {
    await _auth.signOut();
    try {
      await _google.signOut();
    } catch (_) {}
  });

  static String _normalizeEmail(String email) => email.trim().toLowerCase();
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  ref.watch(supabaseClientProvider),
  ref.watch(googleAuthDataSourceProvider),
);
