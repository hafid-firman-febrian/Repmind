import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/env.dart';

part 'google_auth_data_source.g.dart';

class GoogleTokens {
  const GoogleTokens({required this.idToken, required this.accessToken});

  final String idToken;
  final String? accessToken;
}

class GoogleAuthDataSource {
  GoogleAuthDataSource({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Future<GoogleTokens> signIn() async {
    await _ensureInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError(
        'Google returned no ID token. Check GOOGLE_WEB_CLIENT_ID.',
      );
    }
    final authorization = await account.authorizationClient
        .authorizationForScopes(const ['email', 'profile']);
    return GoogleTokens(
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }

  Future<void> _ensureInitialized() =>
      _initialization ??= _googleSignIn.initialize(
        clientId:
            defaultTargetPlatform == TargetPlatform.iOS &&
                Env.googleIosClientId.isNotEmpty
            ? Env.googleIosClientId
            : null,
        serverClientId: Env.googleWebClientId.isEmpty
            ? null
            : Env.googleWebClientId,
      );
}

@Riverpod(keepAlive: true)
GoogleAuthDataSource googleAuthDataSource(Ref ref) => GoogleAuthDataSource();
