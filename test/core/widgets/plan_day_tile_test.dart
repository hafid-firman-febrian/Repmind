import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/core/widgets/plan_day_tile.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<List<int>> pumpTile(
    WidgetTester tester, {
    required bool isToday,
  }) async {
    final taps = <int>[];
    await pumpThemed(
      tester,
      PlanDayTile(
        badge: 'D2',
        title: 'Upper Body Push',
        subtitle: 'Upper · 6 exercises',
        trailing: 'Tue',
        isToday: isToday,
        onTap: () => taps.add(1),
      ),
    );
    return taps;
  }

  RoundedRectangleBorder shapeOf(WidgetTester tester) =>
      tester
              .widget<Material>(
                find
                    .ancestor(
                      of: find.text('Upper Body Push'),
                      matching: find.byType(Material),
                    )
                    .first,
              )
              .shape!
          as RoundedRectangleBorder;

  testWidgets('a regular day shows its weekday', (tester) async {
    await pumpTile(tester, isToday: false);

    expect(find.text('D2'), findsOneWidget);
    expect(find.text('Upper · 6 exercises'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('TODAY'), findsNothing);
    expect(shapeOf(tester).side.color, RepmindColors.light.line);
  });

  testWidgets('today is outlined and tagged', (tester) async {
    await pumpTile(tester, isToday: true);

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('Tue'), findsNothing);
    expect(shapeOf(tester).side.color, RepmindColors.light.limeInk);
    expect(shapeOf(tester).side.width, 1.5);
  });

  testWidgets('tapping opens the day', (tester) async {
    final taps = await pumpTile(tester, isToday: false);

    await tester.tap(find.text('Upper Body Push'));

    expect(taps, [1]);
  });
}
