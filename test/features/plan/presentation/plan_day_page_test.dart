import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';
import 'package:repmind/features/plan/presentation/pages/plan_day_page.dart';

import '../../../fakes/fake_active_plan_controller.dart';
import '../../../fixtures/plan_fixtures.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/pump_router.dart';

void main() {
  Future<void> pumpDay(WidgetTester tester, int? dayNumber) async {
    useTallScreen(tester);
    await pumpPage(
      tester,
      PlanDayPage(dayNumber: dayNumber),
      overrides: [
        activePlanControllerProvider.overrideWith(
          () => FakeActivePlanController(samplePlan()),
        ),
      ],
    );
    await tester.pump();
  }

  testWidgets('lists the exercises picked by the AI', (tester) async {
    await pumpDay(tester, 2);

    expect(find.text('DAY 2 · TUE'), findsOneWidget);
    expect(find.text('UPPER BODY PUSH'), findsOneWidget);
    expect(
      find.text('6 exercises · ~45 min · Dumbbells, Bench'),
      findsOneWidget,
    );
    expect(find.text('02'), findsOneWidget);
    expect(find.text('EXERCISES'), findsOneWidget);
    expect(find.text('Dumbbell Bench Press'), findsOneWidget);
    expect(find.text('Chest · Dumbbells, Bench'), findsOneWidget);
    expect(find.text('4 × 8–10'), findsOneWidget);
    expect(find.text('Rest 90s'), findsNWidgets(2));
    expect(find.text('Diamond Push-up'), findsOneWidget);
    expect(find.text('2 × 10'), findsOneWidget);
  });

  testWidgets('explains when the day number is not in the plan', (
    tester,
  ) async {
    await pumpDay(tester, 9);

    expect(
      find.text('This workout is no longer in your plan.'),
      findsOneWidget,
    );
  });

  testWidgets('explains when the day number could not be read', (tester) async {
    await pumpDay(tester, null);

    expect(
      find.text('This workout is no longer in your plan.'),
      findsOneWidget,
    );
  });
}
