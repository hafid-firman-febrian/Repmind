import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/theme/repmind_colors.dart';
import 'package:repmind/features/coach/domain/models/chat_message_model.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_chat_controller.dart';
import 'package:repmind/features/coach/presentation/widgets/review_change_sheet.dart';

import '../../../fakes/fake_coach_chat_controller.dart';
import '../../../fixtures/coach_fixtures.dart';
import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/pump_app.dart';

class _HeldApplyController extends FakeCoachChatController {
  _HeldApplyController();

  final release = Completer<void>();

  @override
  Future<void> applyProposal(String messageId) async {
    applyCalls.add(messageId);
    await release.future;
  }
}

void main() {
  final message = sampleCoachMessage(id: 'c1', withProposal: true);
  final day = samplePlan().days.firstWhere((day) => day.dayNumber == 2);

  Future<FakeCoachChatController> pumpSheet(
    WidgetTester tester, {
    FakeCoachChatController? controller,
    ChatMessage? shown,
  }) async {
    final fake = controller ?? FakeCoachChatController();
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showReviewChangeSheet(
            context,
            message: shown ?? message,
            day: day,
            nextVersion: 2,
          ),
          child: const Text('open'),
        ),
      ),
      overrides: [coachChatControllerProvider.overrideWith(() => fake)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return fake;
  }

  Finder applyButton() => find.widgetWithText(FilledButton, 'Apply as v2');

  testWidgets('lists the whole day with the change marked', (tester) async {
    await pumpSheet(tester);

    expect(find.text('REVIEW CHANGE'), findsOneWidget);
    expect(find.text('UPPER BODY PUSH'), findsOneWidget);
    for (final name in [
      'Dumbbell Bench Press',
      'Dumbbell Shoulder Press',
      'Push-up',
      'Overhead Triceps Extension',
      'Diamond Push-up',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('Dumbbell Lateral Raise'), findsNWidgets(2));

    final removed = tester.widget<Text>(find.text('Dumbbell Shoulder Press'));
    expect(removed.style!.decoration, TextDecoration.lineThrough);
    final untouched = tester.widget<Text>(find.text('Dumbbell Bench Press'));
    expect(untouched.style!.decoration, isNot(TextDecoration.lineThrough));

    final added = find.ancestor(
      of: find.text('3 × 12'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration).color ==
                RepmindColors.light.violetTint,
      ),
    );
    expect(added, findsOneWidget);
    expect(applyButton(), findsOneWidget);
  });

  testWidgets('Cancel closes without applying', (tester) async {
    final fake = await pumpSheet(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewChangeSheet), findsNothing);
    expect(fake.applyCalls, isEmpty);
  });

  testWidgets('a tap outside closes the idle sheet without applying', (
    tester,
  ) async {
    final fake = await pumpSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewChangeSheet), findsNothing);
    expect(fake.applyCalls, isEmpty);
  });

  testWidgets('Apply calls the controller and closes', (tester) async {
    final fake = await pumpSheet(tester);

    await tester.tap(applyButton());
    await tester.pumpAndSettle();

    expect(fake.applyCalls, ['c1']);
    expect(find.byType(ReviewChangeSheet), findsNothing);
  });

  testWidgets(
    'the button shows loading and the sheet stays open while applying',
    (tester) async {
      final fake = _HeldApplyController();
      await pumpSheet(tester, controller: fake);

      await tester.tap(applyButton());
      await tester.pump();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
        reason: 'loading disables the button',
      );
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Cancel'),
            )
            .onPressed,
        isNull,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ReviewChangeSheet), findsOneWidget);

      await tester.drag(find.byType(ReviewChangeSheet), const Offset(0, 400));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ReviewChangeSheet), findsOneWidget);

      fake.release.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(ReviewChangeSheet), findsNothing);
    },
  );

  testWidgets('a failed apply closes the sheet and shows the message', (
    tester,
  ) async {
    final fake = FakeCoachChatController()
      ..applyError = const ProposalOutdated();
    await pumpSheet(tester, controller: fake);

    await tester.tap(applyButton());
    await tester.pumpAndSettle();

    expect(fake.applyCalls, ['c1']);
    expect(find.byType(ReviewChangeSheet), findsNothing);
    expect(
      find.text('Your plan changed since this suggestion.'),
      findsOneWidget,
    );
  });
}
