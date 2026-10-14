import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/profile/data/repositories/profile_repository.dart';
import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';

class TestUserId extends Notifier<String?> {
  TestUserId(this._initial);

  final String? _initial;

  @override
  String? build() => _initial;

  void signInAs(String? userId) => state = userId;
}

final testUserIdProvider = NotifierProvider<TestUserId, String?>(
  () => TestUserId(null),
);

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
        testUserIdProvider.overrideWith(() => TestUserId(userId)),
        currentUserIdProvider.overrideWith(
          (ref) => ref.watch(testUserIdProvider),
        ),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
      retry: (_, _) => null,
    );
    container.listen(profileControllerProvider, (_, _) {});
    return container;
  }

  Profile profileOf(String id) =>
      Profile.fromJson(profileRow(id: id, onboarded: false));

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

  test('reloads the profile when the signed-in user changes', () async {
    when(
      () => repository.fetchProfile('user-1'),
    ).thenAnswer((_) async => sampleProfile());
    final incoming = profileOf('user-2');
    when(
      () => repository.fetchProfile('user-2'),
    ).thenAnswer((_) async => incoming);
    final container = containerFor('user-1');
    await container.read(profileControllerProvider.future);

    container.read(testUserIdProvider.notifier).signInAs('user-2');

    expect(
      await container.read(profileControllerProvider.future),
      same(incoming),
    );
  });

  test(
    'a save that finishes after the user changed does not overwrite the new user',
    () async {
      when(
        () => repository.fetchProfile('user-1'),
      ).thenAnswer((_) async => sampleProfile(onboarded: false));
      final incoming = profileOf('user-2');
      when(
        () => repository.fetchProfile('user-2'),
      ).thenAnswer((_) async => incoming);
      final pendingSave = Completer<Profile>();
      when(
        () => repository.saveDetails(
          'user-1',
          any(),
          completeOnboarding: any(named: 'completeOnboarding'),
        ),
      ).thenAnswer((_) => pendingSave.future);
      final container = containerFor('user-1');
      await container.read(profileControllerProvider.future);
      final notifier = container.read(profileControllerProvider.notifier);

      final save = notifier.saveDetails(sampleDetails);
      container.read(testUserIdProvider.notifier).signInAs('user-2');
      await container.read(profileControllerProvider.future);
      pendingSave.complete(sampleProfile());
      await save;

      expect(container.read(profileControllerProvider).value, same(incoming));
    },
  );

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

  test('updateAiModel saves the choice and replaces the state', () async {
    when(
      () => repository.fetchProfile('user-1'),
    ).thenAnswer((_) async => sampleProfile());
    when(
      () => repository.updateAiModel('user-1', AiModel.geminiPro),
    ).thenAnswer(
      (_) async =>
          Profile.fromJson({...profileRow(), 'ai_model': 'gemini_pro'}),
    );
    final container = containerFor('user-1');
    await container.read(profileControllerProvider.future);

    await container
        .read(profileControllerProvider.notifier)
        .updateAiModel(AiModel.geminiPro);

    expect(
      container.read(profileControllerProvider).value!.aiModel,
      AiModel.geminiPro,
    );
  });
}
