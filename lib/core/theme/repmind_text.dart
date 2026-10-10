import 'package:flutter/material.dart';

import 'repmind_colors.dart';

@immutable
class RepmindText extends ThemeExtension<RepmindText> {
  const RepmindText({
    required this.display,
    required this.headline,
    required this.title,
    required this.section,
    required this.subtitle,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.stat,
    required this.watermark,
  });

  static const displayFamily = 'Barlow Condensed';
  static const bodyFamily = 'Barlow';

  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle section;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle stat;
  final TextStyle watermark;

  static const light = RepmindText(
    display: TextStyle(
      fontFamily: displayFamily,
      fontSize: 54,
      fontWeight: FontWeight.w800,
      height: 0.9,
      color: RepmindColors.inkColor,
    ),
    headline: TextStyle(
      fontFamily: displayFamily,
      fontSize: 36,
      fontWeight: FontWeight.w800,
      height: 0.92,
      color: RepmindColors.inkColor,
    ),
    title: TextStyle(
      fontFamily: displayFamily,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1,
      color: RepmindColors.inkColor,
    ),
    section: TextStyle(
      fontFamily: displayFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: RepmindColors.inkColor,
    ),
    subtitle: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: RepmindColors.inkColor,
    ),
    body: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4,
      color: RepmindColors.inkColor,
    ),
    bodySmall: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: RepmindColors.inkColor,
    ),
    label: TextStyle(
      fontFamily: bodyFamily,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.84,
      color: RepmindColors.inkColor,
    ),
    stat: TextStyle(
      fontFamily: displayFamily,
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1,
      color: RepmindColors.inkColor,
    ),
    watermark: TextStyle(
      fontFamily: displayFamily,
      fontSize: 124,
      fontWeight: FontWeight.w800,
      height: 1,
      color: RepmindColors.inkColor,
    ),
  );

  @override
  RepmindText copyWith() => this;

  @override
  RepmindText lerp(covariant ThemeExtension<RepmindText>? other, double t) =>
      other is RepmindText && t >= 0.5 ? other : this;
}
