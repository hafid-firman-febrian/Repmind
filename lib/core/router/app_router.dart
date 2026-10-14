import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/controllers/auth_status_provider.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/plan/presentation/pages/generating_page.dart';
import '../../features/plan/presentation/pages/plan_day_page.dart';
import '../../features/plan/presentation/pages/plan_page.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'redirect.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStatusProvider, (_, _) => refresh.value++);
  ref.listen(profileControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      auth: authStatusOf(ref.read(authStatusProvider)),
      profile: profileStatusOf(ref.read(profileControllerProvider)),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInPage()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.plan,
                builder: (_, _) => const PlanPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.workoutDay,
        builder: (_, state) => PlanDayPage(
          dayNumber: int.tryParse(state.pathParameters['day'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.generating,
        builder: (_, _) => const GeneratingPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfilePage(),
        routes: [
          GoRoute(path: 'edit', builder: (_, _) => const EditProfilePage()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}
