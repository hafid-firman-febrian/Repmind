import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/profile/data/data_sources/avatar_picker.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repmind/features/profile/presentation/pages/profile_page.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

class _GatedAvatarProfileController extends FakeProfileController {
  _GatedAvatarProfileController(super.initial);

  final pendingUploads = <Completer<void>>[];
  var failuresLeft = 0;

  @override
  Future<void> updateAvatar(Uint8List bytes) {
    if (failuresLeft > 0) {
      failuresLeft--;
      return Future.error(const StorageFailure());
    }
    final upload = Completer<void>();
    pendingUploads.add(upload);
    return upload.future;
  }
}

void main() {
  testWidgets('shows the profile details and signs out', (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile()),
        ),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    await tester.pump();

    expect(find.text('ALEX'), findsOneWidget);
    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Dumbbells, Bench'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pump();

    verify(() => auth.signOut()).called(1);
  });

  testWidgets('shows a sign out failure in a snack bar', (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.signOut()).thenThrow(const NetworkFailure());
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile()),
        ),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Sign out'), 200);
    await tester.tap(find.text('Sign out'));
    await tester.pump();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });

  testWidgets('does not show a stale avatar error while a retry is pending', (
    tester,
  ) async {
    final picker = MockAvatarPicker();
    when(() => picker.pickFromGallery()).thenAnswer((_) async => Uint8List(1));
    final profile = _GatedAvatarProfileController(sampleProfile())
      ..failuresLeft = 1;
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(() => profile),
        avatarPickerProvider.overrideWithValue(picker),
      ],
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text(const StorageFailure().message), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pump();
    await tester.pump();

    expect(profile.pendingUploads, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);

    profile.pendingUploads.single.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
  });
}
