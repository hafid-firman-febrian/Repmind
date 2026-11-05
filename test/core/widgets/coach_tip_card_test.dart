import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/core/widgets/coach_tip_card.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<List<int>> pumpCard(WidgetTester tester) async {
    final taps = <int>[];
    await pumpThemed(
      tester,
      CoachTipCard(text: 'Slow the lowering phase.', onTap: () => taps.add(1)),
    );
    return taps;
  }

  testWidgets('shows the label and text', (tester) async {
    await pumpCard(tester);

    expect(find.text('Coach tip'), findsOneWidget);
    expect(find.text('Slow the lowering phase.'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('tapping calls onTap', (tester) async {
    final taps = await pumpCard(tester);

    await tester.tap(find.text('Slow the lowering phase.'));

    expect(taps, hasLength(1));
  });

  testWidgets('uses violet with white text', (tester) async {
    await pumpCard(tester);

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('Coach tip'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, RepmindColors.light.violet);
    final label = tester.widget<Text>(find.text('Coach tip'));
    expect(label.style?.color, RepmindColors.light.onViolet);
    final body = tester.widget<Text>(find.text('Slow the lowering phase.'));
    expect(body.style?.color, RepmindColors.light.onViolet);
  });

  testWidgets('is at least 48 dp tall and exposed as a button', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCard(tester);

    expect(
      tester.getSize(find.byType(CoachTipCard)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSemantics(find.byType(CoachTipCard)),
      matchesSemantics(
        label: 'Coach tip. Slow the lowering phase.',
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
