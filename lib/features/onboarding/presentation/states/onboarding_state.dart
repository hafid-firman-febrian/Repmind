import '../../../../core/errors/app_exception.dart';
import '../../../profile/presentation/states/profile_draft.dart';

enum OnboardingStep { goal, level, schedule, body }

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.goal,
    this.draft = const ProfileDraft(),
    this.isSubmitting = false,
    this.error,
  });

  final OnboardingStep step;
  final ProfileDraft draft;
  final bool isSubmitting;
  final AppException? error;

  bool get isFirstStep => step == OnboardingStep.values.first;
  bool get isLastStep => step == OnboardingStep.values.last;
  double get progress => (step.index + 1) / OnboardingStep.values.length;

  bool get canContinue => switch (step) {
    OnboardingStep.goal => draft.goal != null,
    OnboardingStep.level => draft.level != null,
    OnboardingStep.schedule => true,
    OnboardingStep.body => draft.hasValidBody,
  };

  OnboardingState copyWith({
    OnboardingStep? step,
    ProfileDraft? draft,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
  }) => OnboardingState(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : error ?? this.error,
  );
}
