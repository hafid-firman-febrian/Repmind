import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:repmind/features/onboarding/presentation/states/onboarding_state.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/domain/models/fitness_level.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';

void main() {
  late FakeProfileController profile;
  late ProviderContainer container;

  OnboardingState state() => container.read(onboardingControllerProvider);
  OnboardingController controller() =>
      container.read(onboardingControllerProvider.notifier);

  void fillEverything() {
    controller().updateDraft(state().draft.copyWith(goal: FitnessGoal.stayFit));
    controller().next();
    controller().updateDraft(
      state().draft.copyWith(level: FitnessLevel.beginner),
    );
    controller().next();
    controller().next();
    controller().updateDraft(
      state().draft.copyWith(weightText: '70', heightText: '170'),
    );
  }

  setUp(() {
    profile = FakeProfileController(sampleProfile(onboarded: false));
    container = ProviderContainer.test(
      overrides: [profileControllerProvider.overrideWith(() => profile)],
      retry: (_, _) => null,
    );
    container.listen(onboardingControllerProvider, (_, _) {});
  });

  test('cannot continue past a step until it is answered', () {
    expect(state().canContinue, isFalse);
    controller().next();
    expect(state().step, OnboardingStep.goal);

    controller().updateDraft(
      state().draft.copyWith(goal: FitnessGoal.loseWeight),
    );
    controller().next();
    expect(state().step, OnboardingStep.level);
  });

  test('back returns to the previous step and stops at the first', () {
    controller().updateDraft(
      state().draft.copyWith(goal: FitnessGoal.loseWeight),
    );
    controller().next();
    controller().back();
    controller().back();
    expect(state().step, OnboardingStep.goal);
  });

  test('submit saves the answers and completes onboarding', () async {
    fillEverything();
    expect(state().isLastStep, isTrue);

    await controller().submit();

    expect(profile.savedDetails, hasLength(1));
    final (details, completeOnboarding) = profile.savedDetails.single;
    expect(details.goal, FitnessGoal.stayFit);
    expect(details.weightKg, 70);
    expect(completeOnboarding, isTrue);
    expect(state().isSubmitting, isFalse);
  });

  test('a failed submit keeps the answers and shows the error', () async {
    fillEverything();
    profile.saveError = const NetworkFailure();

    await controller().submit();

    expect(state().error, isA<NetworkFailure>());
    expect(state().draft.weightText, '70');
    expect(state().step, OnboardingStep.body);
  });
}
