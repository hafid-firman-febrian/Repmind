import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/controllers/auth_status_provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/profile_details.dart';
import '../../domain/models/profile_model.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  Future<Profile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(profileRepositoryProvider).fetchProfile(userId);
  }

  Future<void> saveDetails(
    ProfileDetails details, {
    bool completeOnboarding = false,
  }) async {
    final updated = await ref
        .read(profileRepositoryProvider)
        .saveDetails(
          _requireUserId(),
          details,
          completeOnboarding: completeOnboarding,
        );
    if (ref.mounted) state = AsyncData(updated);
  }

  Future<void> updateAvatar(Uint8List bytes) async {
    final updated = await ref
        .read(profileRepositoryProvider)
        .updateAvatar(_requireUserId(), bytes);
    if (ref.mounted) state = AsyncData(updated);
  }

  String _requireUserId() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw const UnknownFailure();
    return userId;
  }
}
