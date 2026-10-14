import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/controllers/auth_status_provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/ai_model.dart';
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
  }) => _commit(
    (userId, repository) => repository.saveDetails(
      userId,
      details,
      completeOnboarding: completeOnboarding,
    ),
  );

  Future<void> updateAvatar(Uint8List bytes) =>
      _commit((userId, repository) => repository.updateAvatar(userId, bytes));

  Future<void> updateAiModel(AiModel model) =>
      _commit((userId, repository) => repository.updateAiModel(userId, model));

  Future<void> _commit(
    Future<Profile> Function(String userId, ProfileRepository repository) write,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw const UnknownFailure();
    final updated = await write(userId, ref.read(profileRepositoryProvider));
    final stillSameUser = ref.read(currentUserIdProvider) == userId;
    if (ref.mounted && stillSameUser) state = AsyncData(updated);
  }
}
