import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/core/theme/repmind_text.dart';
import 'package:repmind/core/theme/repmind_theme.dart';

void main() {
  final theme = buildRepmindTheme();

  test('maps the Repmind color roles onto the Material color scheme', () {
    expect(theme.colorScheme.primary, const Color(0xFFD4FF3A));
    expect(theme.colorScheme.onPrimary, const Color(0xFF1B1E24));
    expect(theme.colorScheme.secondary, const Color(0xFF6C4DFF));
    expect(theme.colorScheme.tertiary, const Color(0xFFFF6B1A));
    expect(theme.colorScheme.error, const Color(0xFFC8281C));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F7F5));
  });

  test('exposes the design tokens as theme extensions', () {
    expect(theme.extension<RepmindColors>(), RepmindColors.light);
    expect(theme.extension<RepmindText>(), RepmindText.light);
  });

  test('uses Barlow Condensed for headings and Barlow for body text', () {
    final text = theme.extension<RepmindText>()!;
    expect(text.display.fontFamily, 'Barlow Condensed');
    expect(text.display.fontSize, 54);
    expect(text.headline.fontSize, 36);
    expect(text.title.fontSize, 28);
    expect(text.label.fontWeight, FontWeight.w700);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Barlow');
  });

  test('keeps primary-colored widgets readable on the light background', () {
    expect(theme.progressIndicatorTheme.color, RepmindColors.light.limeInk);
    expect(theme.textSelectionTheme.cursorColor, RepmindColors.light.ink);
    expect(
      theme.textButtonTheme.style!.foregroundColor!.resolve(<WidgetState>{}),
      RepmindColors.light.ink,
    );
  });
}
