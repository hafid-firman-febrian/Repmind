import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../data/data_sources/avatar_picker.dart';
import 'profile_controller.dart';

part 'avatar_upload_controller.g.dart';

@riverpod
class AvatarUploadController extends _$AvatarUploadController {
  @override
  FutureOr<void> build() {}

  var _isPicking = false;

  Future<void> pickAndUpload() async {
    if (state.isLoading || _isPicking) return;

    _isPicking = true;
    final picked = await AsyncValue.guard(
      () => runGuarded(ref.read(avatarPickerProvider).pickFromGallery),
    );
    _isPicking = false;
    if (!ref.mounted) return;
    if (picked case AsyncError(:final error, :final stackTrace)) {
      state = AsyncError(error, stackTrace);
      return;
    }
    final bytes = picked.value;
    if (bytes == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(profileControllerProvider.notifier).updateAvatar(bytes),
    );
    if (ref.mounted) state = result;
  }
}
