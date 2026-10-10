import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/profile/data/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  final now = DateTime.utc(2026, 9, 30, 9);
  late MockProfileRemoteDataSource remote;
  late ProfileRepository repository;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepository(remote, clock: () => now);
  });

  test('fetchProfile maps the row to a Profile', () async {
    when(
      () => remote.fetchProfile('user-1'),
    ).thenAnswer((_) async => profileRow());

    final profile = await repository.fetchProfile('user-1');

    expect(profile.displayName, 'Alex');
    expect(profile.isOnboarded, isTrue);
  });

  test('saveDetails marks onboarding complete when asked', () async {
    when(
      () => remote.updateProfile(any(), any()),
    ).thenAnswer((_) async => profileRow());

    await repository.saveDetails(
      'user-1',
      sampleDetails,
      completeOnboarding: true,
    );

    final values =
        verify(
              () => remote.updateProfile('user-1', captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(values, {
      ...sampleDetails.toJson(),
      'onboarded_at': '2026-09-30T09:00:00.000Z',
    });
  });

  test('saveDetails leaves onboarded_at alone for profile edits', () async {
    when(
      () => remote.updateProfile(any(), any()),
    ).thenAnswer((_) async => profileRow());

    await repository.saveDetails(
      'user-1',
      sampleDetails,
      completeOnboarding: false,
    );

    final values =
        verify(
              () => remote.updateProfile('user-1', captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(values.containsKey('onboarded_at'), isFalse);
  });

  test(
    'updateAvatar uploads to the user folder and stores a versioned URL',
    () async {
      const publicUrl =
          'http://127.0.0.1:54321/storage/v1/object/public/avatars/user-1/avatar.jpg';
      when(
        () => remote.uploadAvatar(any(), any()),
      ).thenAnswer((_) async => publicUrl);
      when(
        () => remote.updateProfile(any(), any()),
      ).thenAnswer((_) async => profileRow());

      await repository.updateAvatar('user-1', Uint8List.fromList([1, 2, 3]));

      verify(() => remote.uploadAvatar('user-1/avatar.jpg', any())).called(1);
      verify(
        () => remote.updateProfile('user-1', {
          'avatar_url': '$publicUrl?v=${now.millisecondsSinceEpoch}',
        }),
      ).called(1);
    },
  );

  test('errors are mapped to AppException', () async {
    when(
      () => remote.fetchProfile(any()),
    ).thenThrow(const SocketException('offline'));
    when(
      () => remote.uploadAvatar(any(), any()),
    ).thenThrow(const StorageException('boom'));
    when(
      () => remote.updateProfile(any(), any()),
    ).thenThrow(const PostgrestException(message: 'violates check constraint'));

    await expectLater(
      repository.fetchProfile('user-1'),
      throwsA(isA<NetworkFailure>()),
    );
    await expectLater(
      repository.updateAvatar('user-1', Uint8List(1)),
      throwsA(isA<StorageFailure>()),
    );
    await expectLater(
      repository.saveDetails(
        'user-1',
        sampleDetails,
        completeOnboarding: false,
      ),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
