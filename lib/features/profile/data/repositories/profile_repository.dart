import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/models/ai_model.dart';
import '../../domain/models/profile_details.dart';
import '../../domain/models/profile_model.dart';
import '../data_sources/profile_remote_data_source.dart';

part 'profile_repository.g.dart';

class ProfileRepository {
  ProfileRepository(this._remote, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ProfileRemoteDataSource _remote;
  final DateTime Function() _clock;

  Future<Profile> fetchProfile(String userId) => runGuarded(
    () async => Profile.fromJson(await _remote.fetchProfile(userId)),
  );

  Future<Profile> saveDetails(
    String userId,
    ProfileDetails details, {
    required bool completeOnboarding,
  }) => runGuarded(() async {
    final values = {
      ...details.toJson(),
      if (completeOnboarding)
        'onboarded_at': _clock().toUtc().toIso8601String(),
    };
    return Profile.fromJson(await _remote.updateProfile(userId, values));
  });

  Future<Profile> updateAvatar(String userId, Uint8List bytes) => runGuarded(
    () async {
      final publicUrl = await _remote.uploadAvatar('$userId/avatar.jpg', bytes);
      final versionedUrl = '$publicUrl?v=${_clock().millisecondsSinceEpoch}';
      return Profile.fromJson(
        await _remote.updateProfile(userId, {'avatar_url': versionedUrl}),
      );
    },
  );

  Future<Profile> updateAiModel(String userId, AiModel model) => runGuarded(
    () async => Profile.fromJson(
      await _remote.updateProfile(userId, {'ai_model': model.dbValue}),
    ),
  );
}

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => ProfileRepository(
  ProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
);
