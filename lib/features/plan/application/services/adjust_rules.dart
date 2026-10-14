abstract final class AdjustRules {
  static const minLength = 3;
  static const maxLength = 200;

  static const suggestions = [
    'Shorter sessions',
    'More core work',
    'No barbell',
    'Swap leg day to Friday',
  ];

  static String? validateInstruction(String raw) {
    final length = raw.trim().length;
    if (length < minLength) {
      return 'Tell the AI a bit more (at least $minLength characters).';
    }
    if (length > maxLength) return 'Keep it under $maxLength characters.';
    return null;
  }
}
