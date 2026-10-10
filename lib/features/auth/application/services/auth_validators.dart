abstract final class AuthValidators {
  static const minPasswordLength = 8;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Enter your name.' : null;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) =>
      (value == null || value.length < minPasswordLength)
      ? 'Use at least $minPasswordLength characters.'
      : null;

  static String? signInPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Enter your password.' : null;
}
