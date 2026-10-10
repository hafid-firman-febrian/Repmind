import 'package:flutter/material.dart';

@immutable
class RepmindColors extends ThemeExtension<RepmindColors> {
  const RepmindColors({
    required this.lime,
    required this.limeInk,
    required this.violet,
    required this.violetTint,
    required this.violetLine,
    required this.orange,
    required this.orangeMark,
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.line,
    required this.ink,
    required this.muted,
    required this.chartMuted,
    required this.danger,
    required this.onLime,
    required this.onViolet,
    required this.onOrange,
  });

  final Color lime;
  final Color limeInk;
  final Color violet;
  final Color violetTint;
  final Color violetLine;
  final Color orange;
  final Color orangeMark;
  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color line;
  final Color ink;
  final Color muted;
  final Color chartMuted;
  final Color danger;
  final Color onLime;
  final Color onViolet;
  final Color onOrange;

  static const inkColor = Color(0xFF1B1E24);

  static const light = RepmindColors(
    lime: Color(0xFFD4FF3A),
    limeInk: Color(0xFF4D7000),
    violet: Color(0xFF6C4DFF),
    violetTint: Color(0xFFEFEBFF),
    violetLine: Color(0xFFDCD4FF),
    orange: Color(0xFFFF6B1A),
    orangeMark: Color(0xFFF25A0F),
    background: Color(0xFFF6F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEEF0EC),
    line: Color(0xFFE3E5E1),
    ink: inkColor,
    muted: Color(0xFF6B6F78),
    chartMuted: Color(0xFF8E929A),
    danger: Color(0xFFC8281C),
    onLime: inkColor,
    onViolet: Color(0xFFFFFFFF),
    onOrange: inkColor,
  );

  Color get limeEdge => ink.withValues(alpha: 0.08);

  @override
  RepmindColors copyWith() => this;

  @override
  RepmindColors lerp(
    covariant ThemeExtension<RepmindColors>? other,
    double t,
  ) => other is RepmindColors && t >= 0.5 ? other : this;
}
