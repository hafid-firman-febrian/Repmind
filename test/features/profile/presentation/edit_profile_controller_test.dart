import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/profile/domain/models/fitness_goal.dart';
import 'package:repmind/features/profile/presentation/controllers/edit_profile_controller.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';

void main() {
  late FakeProfileController profile;
  late ProviderContainer container;

  setUp(() async {
    profile = FakeProfileController(sampleProfile());
    container = ProviderContainer.test(
      overrides: [profileControllerProvider.overrideWith(() => profile)],
      retry: (_, _) => null,
    );
    await container.read(profileControllerProvider.future);
    container.listen(editProfileControllerProvider, (_, _) {});
  });

  test('starts from the saved profile', () {
    final draft = container.read(editProfileControllerProvider).draft;
    expect(draft.goal, FitnessGoal.buildMuscle);
    expect(draft.weightText, '72.5');
  });

  test('save writes the edits without touching onboarding', () async {
    final controller = container.read(editProfileControllerProvider.notifier);
    controller.updateDraft(
      container
          .read(editProfileControllerProvider)
          .draft
          .copyWith(goal: FitnessGoal.stayFit),
    );

    expect(await controller.save(), isTrue);

    final (details, completeOnboarding) = profile.savedDetails.single;
    expect(details.goal, FitnessGoal.stayFit);
    expect(completeOnboarding, isFalse);
  });

  test('a failed save reports false and keeps the error', () async {
    profile.saveError = const NetworkFailure();

    expect(
      await container.read(editProfileControllerProvider.notifier).save(),
      isFalse,
    );
    expect(
      container.read(editProfileControllerProvider).error,
      isA<NetworkFailure>(),
    );
  });
}
