import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/models/auth_status.dart';
import '../../features/profile/domain/models/profile_model.dart';
import '../../features/profile/domain/models/profile_status.dart';
import 'app_routes.dart';

String? resolveRedirect({
  required AuthStatus auth,
  required ProfileStatus profile,
  required String location,
}) {
  String? stayOn(String route) => location == route ? null : route;

  return switch (auth) {
    AuthStatus.loading => stayOn(AppRoutes.splash),
    AuthStatus.signedOut =>
      AppRoutes.authRoutes.contains(location) ? null : AppRoutes.welcome,
    AuthStatus.signedIn => switch (profile) {
      ProfileStatus.loading || ProfileStatus.failed => stayOn(AppRoutes.splash),
      ProfileStatus.notOnboarded => stayOn(AppRoutes.onboarding),
      ProfileStatus.onboarded => _isGateRoute(location) ? AppRoutes.home : null,
    },
  };
}

bool _isGateRoute(String location) =>
    AppRoutes.authRoutes.contains(location) ||
    location == AppRoutes.onboarding ||
    location == AppRoutes.splash;

AuthStatus authStatusOf(AsyncValue<AuthStatus> value) =>
    value.value ?? (value.hasError ? AuthStatus.signedOut : AuthStatus.loading);

ProfileStatus profileStatusOf(AsyncValue<Profile?> value) {
  final profile = value.value;
  if (profile != null) {
    return profile.isOnboarded
        ? ProfileStatus.onboarded
        : ProfileStatus.notOnboarded;
  }
  return value.hasError ? ProfileStatus.failed : ProfileStatus.loading;
}
