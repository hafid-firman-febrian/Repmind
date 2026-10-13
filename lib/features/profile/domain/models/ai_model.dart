enum AiModel {
  geminiFlash('gemini_flash', 'Gemini 3.8 Flash', 'Balanced · default'),
  geminiFlashLite('gemini_flash_lite', 'Gemini 3.5 Flash-Lite', 'Fastest'),
  geminiPro('gemini_pro', 'Gemini 3.1 Pro', 'Best reasoning · slower');

  const AiModel(this.dbValue, this.label, this.description);

  final String dbValue;
  final String label;
  final String description;

  static AiModel fromDb(String value) =>
      values.firstWhere((model) => model.dbValue == value);
}
