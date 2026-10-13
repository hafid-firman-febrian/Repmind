import '../../../../core/errors/app_exception.dart';
import 'profile_draft.dart';

class EditProfileState {
  const EditProfileState({
    required this.draft,
    this.isSubmitting = false,
    this.error,
  });

  final ProfileDraft draft;
  final bool isSubmitting;
  final AppException? error;

  EditProfileState copyWith({
    ProfileDraft? draft,
    bool? isSubmitting,
    AppException? error,
    bool clearError = false,
  }) => EditProfileState(
    draft: draft ?? this.draft,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: clearError ? null : error ?? this.error,
  );
}
