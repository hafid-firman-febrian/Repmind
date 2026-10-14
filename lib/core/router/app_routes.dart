abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const plan = '/plan';
  static const generating = '/generating';
  static const workoutDay = '/workout/:day';

  static String workoutDayPath(int dayNumber) => '/workout/$dayNumber';

  static const authRoutes = {welcome, signIn, signUp};
}
