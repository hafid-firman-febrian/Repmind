import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/core/widgets/week_strip.dart';

import '../../helpers/pump_app.dart';

void main() {
  const items = [
    WeekStripItem(
      dayName: 'Monday',
      status: WeekStripStatus.scheduled,
      isToday: false,
    ),
    WeekStripItem(
      dayName: 'Tuesday',
      status: WeekStripStatus.scheduled,
      isToday: true,
    ),
    WeekStripItem(
      dayName: 'Wednesday',
      status: WeekStripStatus.rest,
      isToday: false,
    ),
    WeekStripItem(
      dayName: 'Thursday',
      status: WeekStripStatus.scheduled,
      isToday: false,
    ),
    WeekStripItem(
      dayName: 'Friday',
      status: WeekStripStatus.rest,
      isToday: false,
    ),
    WeekStripItem(
      dayName: 'Saturday',
      status: WeekStripStatus.scheduled,
      isToday: false,
    ),
    WeekStripItem(
      dayName: 'Sunday',
      status: WeekStripStatus.rest,
      isToday: false,
    ),
  ];

  BoxDecoration markOf(WidgetTester tester, String dayName) =>
      tester
              .widget<Container>(
                find.byKey(ValueKey('week-strip-mark-$dayName')),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('shows one letter per day', (tester) async {
    await pumpThemed(tester, const WeekStrip(items: items));

    expect(find.text('M'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2));
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2));
  });

  testWidgets('scheduled days are filled and today has a lime ink ring', (
    tester,
  ) async {
    await pumpThemed(tester, const WeekStrip(items: items));

    final monday = markOf(tester, 'Monday');
    final tuesday = markOf(tester, 'Tuesday');
    final wednesday = markOf(tester, 'Wednesday');
    expect(monday.color, RepmindColors.light.surfaceSunken);
    expect(monday.border, isNull);
    expect((tuesday.border! as Border).top.color, RepmindColors.light.limeInk);
    expect(wednesday.color, isNull);
  });

  testWidgets('describes each day for screen readers', (tester) async {
    await pumpThemed(tester, const WeekStrip(items: items));

    expect(find.bySemanticsLabel('Tuesday, workout, today'), findsOneWidget);
    expect(find.bySemanticsLabel('Wednesday, rest'), findsOneWidget);
  });
}
