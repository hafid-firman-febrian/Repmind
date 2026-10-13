import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../states/edit_profile_state.dart';
import '../states/profile_draft.dart';
import 'profile_controller.dart';

part 'edit_profile_controller.g.dart';

@riverpod
class EditProfileController extends _$EditProfileController {
  @override
  EditProfileState build() {
    final details = ref.read(profileControllerProvider).value?.details;
    return EditProfileState(
      draft: details == null
          ? const ProfileDraft()
          : ProfileDraft.fromDetails(details),
    );
  }

  void updateDraft(ProfileDraft draft) =>
      state = state.copyWith(draft: draft, clearError: true);

  Future<bool> save() async {
    final details = state.draft.toDetails();
    if (details == null || state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(profileControllerProvider.notifier).saveDetails(details);
      if (ref.mounted) state = state.copyWith(isSubmitting: false);
      return true;
    } on AppException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false, error: error);
      }
      return false;
    }
  }
}
