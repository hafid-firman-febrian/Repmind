import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/router/app_routes.dart';
import 'package:repmind/core/router/redirect.dart';
import 'package:repmind/features/auth/domain/models/auth_status.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/domain/models/profile_status.dart';

import '../../fixtures/profile_fixtures.dart';

void main() {
  String? go(AuthStatus auth, ProfileStatus profile, String location) =>
      resolveRedirect(auth: auth, profile: profile, location: location);

  group('resolveRedirect', () {
    test('waits on splash while auth is loading', () {
      expect(
        go(AuthStatus.loading, ProfileStatus.loading, AppRoutes.home),
        AppRoutes.splash,
      );
      expect(
        go(AuthStatus.loading, ProfileStatus.loading, AppRoutes.splash),
        isNull,
      );
    });

    test('signed-out users may only visit auth routes', () {
      expect(
        go(AuthStatus.signedOut, ProfileStatus.loading, AppRoutes.splash),
        AppRoutes.welcome,
      );
      expect(
        go(AuthStatus.signedOut, ProfileStatus.loading, AppRoutes.home),
        AppRoutes.welcome,
      );
      expect(
        go(AuthStatus.signedOut, ProfileStatus.loading, AppRoutes.signIn),
        isNull,
      );
      expect(
        go(AuthStatus.signedOut, ProfileStatus.loading, AppRoutes.signUp),
        isNull,
      );
      expect(
        go(AuthStatus.signedOut, ProfileStatus.loading, AppRoutes.welcome),
        isNull,
      );
    });

    test(
      'signed-in users wait on splash while the profile loads or failed',
      () {
        for (final status in [ProfileStatus.loading, ProfileStatus.failed]) {
          expect(
            go(AuthStatus.signedIn, status, AppRoutes.signIn),
            AppRoutes.splash,
          );
          expect(go(AuthStatus.signedIn, status, AppRoutes.splash), isNull);
        }
      },
    );

    test('signed-in users without onboarding go to onboarding', () {
      expect(
        go(AuthStatus.signedIn, ProfileStatus.notOnboarded, AppRoutes.signUp),
        AppRoutes.onboarding,
      );
      expect(
        go(AuthStatus.signedIn, ProfileStatus.notOnboarded, AppRoutes.home),
        AppRoutes.onboarding,
      );
      expect(
        go(
          AuthStatus.signedIn,
          ProfileStatus.notOnboarded,
          AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('onboarded users leave gate routes for home', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.signUp,
        AppRoutes.onboarding,
      ]) {
        expect(
          go(AuthStatus.signedIn, ProfileStatus.onboarded, location),
          AppRoutes.home,
        );
      }
    });

    test('onboarded users stay on app routes', () {
      for (final location in [
        AppRoutes.home,
        AppRoutes.profile,
        AppRoutes.editProfile,
        AppRoutes.plan,
        AppRoutes.generating,
        AppRoutes.workoutDayPath(2),
      ]) {
        expect(
          go(AuthStatus.signedIn, ProfileStatus.onboarded, location),
          isNull,
        );
      }
    });
  });

  group('status mappers', () {
    test('authStatusOf', () {
      expect(authStatusOf(const AsyncLoading()), AuthStatus.loading);
      expect(
        authStatusOf(const AsyncData(AuthStatus.signedIn)),
        AuthStatus.signedIn,
      );
      expect(
        authStatusOf(AsyncError(Exception('x'), StackTrace.empty)),
        AuthStatus.signedOut,
      );
    });

    test('profileStatusOf', () {
      expect(profileStatusOf(const AsyncLoading()), ProfileStatus.loading);
      expect(
        profileStatusOf(AsyncData<Profile?>(sampleProfile())),
        ProfileStatus.onboarded,
      );
      expect(
        profileStatusOf(AsyncData<Profile?>(sampleProfile(onboarded: false))),
        ProfileStatus.notOnboarded,
      );
      expect(
        profileStatusOf(
          const AsyncError<Profile?>(NetworkFailure(), StackTrace.empty),
        ),
        ProfileStatus.failed,
      );
    });
  });
}
