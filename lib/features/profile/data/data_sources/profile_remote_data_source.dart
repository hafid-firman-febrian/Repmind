import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  static const _table = 'profiles';
  static const _avatarBucket = 'avatars';

  final SupabaseClient _client;

  Future<Map<String, dynamic>> fetchProfile(String userId) =>
      _client.from(_table).select().eq('id', userId).single();

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> values,
  ) => _client.from(_table).update(values).eq('id', userId).select().single();

  Future<String> uploadAvatar(String path, Uint8List bytes) async {
    final bucket = _client.storage.from(_avatarBucket);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return bucket.getPublicUrl(path);
  }
}
