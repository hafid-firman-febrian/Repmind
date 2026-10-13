import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/widgets/primary_button.dart';
import 'package:repmind/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/pump_app.dart';

void main() {
  FilledButton nextButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.byType(FilledButton),
    ),
  );

  testWidgets('Next is disabled until a goal is picked', (tester) async {
    await pumpPage(
      tester,
      const OnboardingPage(),
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile(onboarded: false)),
        ),
      ],
    );

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(nextButton(tester).onPressed, isNull);

    await tester.tap(find.text('Build muscle'));
    await tester.pump();

    expect(nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('a failed submit shows a snack bar and keeps the answers', (
    tester,
  ) async {
    final profile = FakeProfileController(sampleProfile(onboarded: false))
      ..saveError = const NetworkFailure();
    await pumpPage(
      tester,
      const OnboardingPage(),
      overrides: [profileControllerProvider.overrideWith(() => profile)],
    );

    await tester.tap(find.text('Build muscle'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Beginner'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('weight-field')), '70');
    await tester.enterText(find.byKey(const ValueKey('height-field')), '170');
    await tester.pump();
    await tester.tap(find.text('Finish'));
    await tester.pump();
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(const NetworkFailure().message),
      ),
      findsOneWidget,
    );
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('170'), findsOneWidget);
  });
}
