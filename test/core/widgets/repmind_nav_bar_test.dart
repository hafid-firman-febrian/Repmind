import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/core/widgets/repmind_nav_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  List<RepmindNavItem> itemsWith({bool coachEnabled = false}) => [
    const RepmindNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      tone: NavTone.lime,
    ),
    const RepmindNavItem(
      icon: Icons.calendar_today_rounded,
      label: 'Plan',
      tone: NavTone.lime,
    ),
    RepmindNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Coach',
      tone: NavTone.violet,
      enabled: coachEnabled,
    ),
    const RepmindNavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Progress',
      tone: NavTone.orange,
      enabled: false,
    ),
  ];

  Future<List<int>> pumpBar(
    WidgetTester tester, {
    required int currentIndex,
    bool coachEnabled = false,
  }) async {
    final selected = <int>[];
    await pumpThemed(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: RepmindNavBar(
          items: itemsWith(coachEnabled: coachEnabled),
          currentIndex: currentIndex,
          onSelected: selected.add,
        ),
      ),
    );
    return selected;
  }

  Material tabOf(WidgetTester tester, IconData icon) => tester.widget<Material>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(Material)).first,
  );

  Icon iconOf(WidgetTester tester, IconData icon) =>
      tester.widget<Icon>(find.byIcon(icon));

  testWidgets('fills the active tab with its role color', (tester) async {
    await pumpBar(tester, currentIndex: 1);

    expect(
      tabOf(tester, Icons.calendar_today_rounded).color,
      RepmindColors.light.lime,
    );
    expect(
      iconOf(tester, Icons.calendar_today_rounded).color,
      RepmindColors.light.ink,
    );
    expect(iconOf(tester, Icons.home_rounded).color, RepmindColors.light.muted);
  });

  testWidgets('an active violet tab shows a white icon', (tester) async {
    await pumpBar(tester, currentIndex: 2, coachEnabled: true);

    expect(
      tabOf(tester, Icons.chat_bubble_outline_rounded).color,
      RepmindColors.light.violet,
    );
    expect(
      iconOf(tester, Icons.chat_bubble_outline_rounded).color,
      RepmindColors.light.onViolet,
    );
  });

  testWidgets('selecting an enabled tab reports its index', (tester) async {
    final selected = await pumpBar(tester, currentIndex: 1);

    await tester.tap(find.byTooltip('Home'));

    expect(selected, [0]);
  });

  testWidgets('Coach and Progress cannot be tapped yet', (tester) async {
    final selected = await pumpBar(tester, currentIndex: 0);

    await tester.tap(find.byTooltip('Coach'));
    await tester.tap(find.byTooltip('Progress'));

    expect(selected, isEmpty);
  });
}
