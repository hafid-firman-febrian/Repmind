import 'package:flutter/material.dart';

import 'repmind_colors.dart';
import 'repmind_radius.dart';
import 'repmind_text.dart';

ThemeData buildRepmindTheme() {
  const colors = RepmindColors.light;
  const text = RepmindText.light;

  final scheme = ColorScheme.fromSeed(seedColor: colors.lime).copyWith(
    primary: colors.lime,
    onPrimary: colors.onLime,
    secondary: colors.violet,
    onSecondary: colors.onViolet,
    tertiary: colors.orange,
    onTertiary: colors.onOrange,
    surface: colors.surface,
    onSurface: colors.ink,
    error: colors.danger,
    onError: colors.surface,
    outline: colors.line,
  );

  OutlineInputBorder fieldBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(RepmindRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: RepmindText.bodyFamily,
    textTheme: TextTheme(
      displayLarge: text.display,
      headlineMedium: text.headline,
      titleLarge: text.title,
      titleMedium: text.subtitle,
      titleSmall: text.section,
      bodyMedium: text.body,
      bodySmall: text.bodySmall,
      labelSmall: text.label,
    ),
    extensions: const [colors, text],
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.limeInk,
      linearTrackColor: colors.line,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.ink,
        textStyle: text.subtitle,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.ink,
      selectionColor: colors.lime,
      selectionHandleColor: colors.limeInk,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: text.body.copyWith(color: colors.muted),
      suffixStyle: text.body.copyWith(color: colors.muted),
      errorStyle: text.bodySmall.copyWith(color: colors.danger),
      border: fieldBorder(colors.line),
      enabledBorder: fieldBorder(colors.line),
      focusedBorder: fieldBorder(colors.ink, width: 1.5),
      errorBorder: fieldBorder(colors.danger),
      focusedErrorBorder: fieldBorder(colors.danger, width: 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.ink,
      contentTextStyle: text.body.copyWith(color: colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RepmindRadius.button),
      ),
    ),
  );
}
