import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/profile/data/repositories/profile_repository.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository repository;

  setUpAll(() {
    registerFallbackValue(sampleDetails);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() => repository = MockProfileRepository());

  ProviderContainer containerFor(String? userId) {
    final container = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      retry: (_, _) => null,
    );
    container.listen(profileControllerProvider, (_, _) {});
    return container;
  }

  test('loads the profile of the signed-in user', () async {
    final profile = sampleProfile();
    when(
      () => repository.fetchProfile('user-1'),
    ).thenAnswer((_) async => profile);

    final container = containerFor('user-1');

    expect(
      await container.read(profileControllerProvider.future),
      same(profile),
    );
  });

  test('is null when nobody is signed in', () async {
    final container = containerFor(null);

    expect(await container.read(profileControllerProvider.future), isNull);
    verifyNever(() => repository.fetchProfile(any()));
  });

  test('saveDetails replaces the state with the saved profile', () async {
    when(
      () => repository.fetchProfile('user-1'),
    ).thenAnswer((_) async => sampleProfile(onboarded: false));
    when(
      () => repository.saveDetails('user-1', any(), completeOnboarding: true),
    ).thenAnswer((_) async => sampleProfile());
    final container = containerFor('user-1');
    await container.read(profileControllerProvider.future);

    await container
        .read(profileControllerProvider.notifier)
        .saveDetails(sampleDetails, completeOnboarding: true);

    expect(
      container.read(profileControllerProvider).value!.isOnboarded,
      isTrue,
    );
  });

  test(
    'a failed save rethrows and keeps the current profile on screen',
    () async {
      final current = sampleProfile(onboarded: false);
      when(
        () => repository.fetchProfile('user-1'),
      ).thenAnswer((_) async => current);
      when(
        () => repository.saveDetails(
          any(),
          any(),
          completeOnboarding: any(named: 'completeOnboarding'),
        ),
      ).thenThrow(const NetworkFailure());
      final container = containerFor('user-1');
      await container.read(profileControllerProvider.future);

      await expectLater(
        container
            .read(profileControllerProvider.notifier)
            .saveDetails(sampleDetails),
        throwsA(isA<NetworkFailure>()),
      );
      expect(container.read(profileControllerProvider).value, same(current));
    },
  );

  test(
    'a failed avatar upload rethrows and keeps the current profile',
    () async {
      final current = sampleProfile();
      when(
        () => repository.fetchProfile('user-1'),
      ).thenAnswer((_) async => current);
      when(
        () => repository.updateAvatar(any(), any()),
      ).thenThrow(const StorageFailure());
      final container = containerFor('user-1');
      await container.read(profileControllerProvider.future);

      await expectLater(
        container
            .read(profileControllerProvider.notifier)
            .updateAvatar(Uint8List(1)),
        throwsA(isA<StorageFailure>()),
      );
      expect(container.read(profileControllerProvider).value, same(current));
    },
  );
}
