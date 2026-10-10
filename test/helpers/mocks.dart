import 'package:mocktail/mocktail.dart';
import 'package:repmind/features/auth/data/data_sources/google_auth_data_source.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/profile/data/data_sources/avatar_picker.dart';
import 'package:repmind/features/profile/data/data_sources/profile_remote_data_source.dart';
import 'package:repmind/features/profile/data/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockGoogleAuthDataSource extends Mock implements GoogleAuthDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAvatarPicker extends Mock implements AvatarPicker {}
