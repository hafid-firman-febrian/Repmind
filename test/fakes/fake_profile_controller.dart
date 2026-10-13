import 'dart:typed_data';

import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/domain/models/profile_details.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

class FakeProfileController extends ProfileController {
  FakeProfileController(this.initial, {this.loadError});

  final Profile? initial;
  final Object? loadError;
  Object? saveError;
  Object? avatarError;
  Object? aiModelError;
  final savedDetails = <(ProfileDetails, bool)>[];
  final uploadedAvatars = <Uint8List>[];
  final updatedAiModels = <AiModel>[];

  @override
  Future<Profile?> build() async {
    final error = loadError;
    if (error != null) throw error;
    return initial;
  }

  @override
  Future<void> saveDetails(
    ProfileDetails details, {
    bool completeOnboarding = false,
  }) async {
    final error = saveError;
    if (error != null) throw error;
    savedDetails.add((details, completeOnboarding));
  }

  @override
  Future<void> updateAvatar(Uint8List bytes) async {
    final error = avatarError;
    if (error != null) throw error;
    uploadedAvatars.add(bytes);
  }

  @override
  Future<void> updateAiModel(AiModel model) async {
    final error = aiModelError;
    if (error != null) throw error;
    updatedAiModels.add(model);
  }
}
