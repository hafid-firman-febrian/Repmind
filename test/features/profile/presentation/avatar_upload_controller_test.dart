import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/profile/data/data_sources/avatar_picker.dart';
import 'package:repmind/features/profile/presentation/controllers/avatar_upload_controller.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late FakeProfileController profile;
  late MockAvatarPicker picker;
  late ProviderContainer container;

  setUp(() {
    profile = FakeProfileController(sampleProfile());
    picker = MockAvatarPicker();
    container = ProviderContainer.test(
      overrides: [
        profileControllerProvider.overrideWith(() => profile),
        avatarPickerProvider.overrideWithValue(picker),
      ],
      retry: (_, _) => null,
    );
    container.listen(avatarUploadControllerProvider, (_, _) {});
  });

  test('does nothing when the user closes the picker', () async {
    when(() => picker.pickFromGallery()).thenAnswer((_) async => null);

    await container
        .read(avatarUploadControllerProvider.notifier)
        .pickAndUpload();

    expect(profile.uploadedAvatars, isEmpty);
    expect(
      container.read(avatarUploadControllerProvider),
      isA<AsyncData<void>>(),
    );
  });

  test('uploads the picked photo', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => picker.pickFromGallery()).thenAnswer((_) async => bytes);

    await container
        .read(avatarUploadControllerProvider.notifier)
        .pickAndUpload();

    expect(profile.uploadedAvatars.single, bytes);
  });

  test('exposes upload failures', () async {
    when(() => picker.pickFromGallery()).thenAnswer((_) async => Uint8List(1));
    profile.avatarError = const StorageFailure();

    await container
        .read(avatarUploadControllerProvider.notifier)
        .pickAndUpload();

    expect(
      container.read(avatarUploadControllerProvider).error,
      isA<StorageFailure>(),
    );
  });

  test('turns a picker failure into an AppException error state', () async {
    when(() => picker.pickFromGallery()).thenThrow(StateError('picker broke'));

    await container
        .read(avatarUploadControllerProvider.notifier)
        .pickAndUpload();

    expect(
      container.read(avatarUploadControllerProvider).error,
      isA<UnknownFailure>(),
    );
    expect(profile.uploadedAvatars, isEmpty);
  });

  test('ignores a second pick while the picker is still open', () async {
    final pending = Completer<Uint8List?>();
    when(() => picker.pickFromGallery()).thenAnswer((_) => pending.future);
    final controller = container.read(avatarUploadControllerProvider.notifier);

    final first = controller.pickAndUpload();
    final second = controller.pickAndUpload();
    pending.complete(null);
    await Future.wait([first, second]);

    verify(() => picker.pickFromGallery()).called(1);
  });

  test('allows picking again after the picker is closed', () async {
    when(() => picker.pickFromGallery()).thenAnswer((_) async => null);
    final controller = container.read(avatarUploadControllerProvider.notifier);

    await controller.pickAndUpload();
    await controller.pickAndUpload();

    verify(() => picker.pickFromGallery()).called(2);
  });
}
