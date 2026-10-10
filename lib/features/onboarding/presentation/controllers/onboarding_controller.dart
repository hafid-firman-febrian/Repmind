import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/states/profile_draft.dart';
import '../states/onboarding_state.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  void updateDraft(ProfileDraft draft) =>
      state = state.copyWith(draft: draft, clearError: true);

  void next() {
    if (!state.canContinue || state.isLastStep) return;
    state = state.copyWith(step: OnboardingStep.values[state.step.index + 1]);
  }

  void back() {
    if (state.isFirstStep || state.isSubmitting) return;
    state = state.copyWith(step: OnboardingStep.values[state.step.index - 1]);
  }

  Future<void> submit() async {
    final details = state.draft.toDetails();
    if (details == null || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .saveDetails(details, completeOnboarding: true);
      if (ref.mounted) state = state.copyWith(isSubmitting: false);
    } on AppException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false, error: error);
      }
    }
  }
}
