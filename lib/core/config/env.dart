abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static void ensureSupabaseConfigured() {
    final missing = missingKeys({
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_PUBLISHABLE_KEY': supabasePublishableKey,
    });
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing ${missing.join(', ')}. '
        'Run the app with --dart-define-from-file=env/dev.json.',
      );
    }
  }

  static List<String> missingKeys(Map<String, String> values) => [
    for (final MapEntry(:key, :value) in values.entries)
      if (value.trim().isEmpty) key,
  ];
}
