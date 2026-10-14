import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/widgets/option_chip.dart';
import 'package:repmind/features/plan/presentation/widgets/adjust_plan_sheet.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<List<String?>> pumpSheet(WidgetTester tester) async {
    final results = <String?>[];
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(
            await showAdjustPlanSheet(context, currentVersion: 1),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  VoidCallback? generateAction(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, 'Generate v2'))
      .onPressed;

  testWidgets('shows the copy, the suggestions and the next version', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.text('ADJUST YOUR PLAN'), findsOneWidget);
    expect(
      find.text('Tell the AI what to change. Your current plan is kept as v1.'),
      findsOneWidget,
    );
    for (final suggestion in [
      'Shorter sessions',
      'More core work',
      'No barbell',
      'Swap leg day to Friday',
    ]) {
      expect(find.widgetWithText(OptionChip, suggestion), findsOneWidget);
    }
    expect(find.text('Generate v2'), findsOneWidget);
  });

  testWidgets('stays disabled until the instruction is long enough', (
    tester,
  ) async {
    await pumpSheet(tester);
    expect(generateAction(tester), isNull);

    for (final text in ['   ', 'ab']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
      expect(generateAction(tester), isNull, reason: text);
    }

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(generateAction(tester), isNotNull);
  });

  testWidgets('a suggestion fills the field', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.widgetWithText(OptionChip, 'More core work'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'More core work');
  });

  testWidgets('submitting returns the trimmed instruction', (tester) async {
    final results = await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), '  More core work  ');
    await tester.pump();
    await tester.tap(find.text('Generate v2'));
    await tester.pumpAndSettle();

    expect(results, ['More core work']);
  });

  testWidgets('the button can be scrolled above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpSheet(tester);

    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();

    final keyboardTop = (1600 - 600) / 2;
    final buttonBottom = tester
        .getBottomLeft(find.widgetWithText(FilledButton, 'Generate v2'))
        .dy;
    expect(buttonBottom, lessThanOrEqualTo(keyboardTop));
  });

  testWidgets('closing the sheet returns nothing', (tester) async {
    final results = await pumpSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(results, [null]);
  });
}
