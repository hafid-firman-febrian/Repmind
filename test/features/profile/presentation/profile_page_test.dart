import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/widgets/selectable_card.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/profile/data/data_sources/avatar_picker.dart';
import 'package:repmind/features/profile/domain/models/ai_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repmind/features/profile/presentation/pages/profile_page.dart';
import 'package:repmind/features/profile/presentation/widgets/profile_avatar.dart';

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

  testWidgets('tapping the large avatar opens the photo picker', (
    tester,
  ) async {
    final picker = MockAvatarPicker();
    when(() => picker.pickFromGallery()).thenAnswer((_) async => null);
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile()),
        ),
        avatarPickerProvider.overrideWithValue(picker),
      ],
    );
    await tester.pump();

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pump();

    verify(() => picker.pickFromGallery()).called(1);
  });

  testWidgets('labels both photo targets and disables them while uploading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final picker = MockAvatarPicker();
    when(() => picker.pickFromGallery()).thenAnswer((_) async => Uint8List(1));
    final profile = _GatedAvatarProfileController(sampleProfile());
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(() => profile),
        avatarPickerProvider.overrideWithValue(picker),
      ],
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Change photo'), findsWidgets);
    expect(find.byTooltip('Change photo'), findsOneWidget);

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pump();
    await tester.pump();
    expect(profile.pendingUploads, hasLength(1));

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pump();

    verify(() => picker.pickFromGallery()).called(1);
    profile.pendingUploads.single.complete();
    await tester.pump();
    semantics.dispose();
  });

  Future<FakeProfileController> pumpForAiModel(WidgetTester tester) async {
    final profile = FakeProfileController(sampleProfile());
    await pumpPage(
      tester,
      const ProfilePage(),
      overrides: [
        profileControllerProvider.overrideWith(() => profile),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    await tester.pump();
    await tester.scrollUntilVisible(find.text('AI model'), 200);
    return profile;
  }

  Future<void> chooseModel(WidgetTester tester, String label) async {
    await tester.tap(find.text('AI model'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SelectableCard, label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the AI model in the profile details', (tester) async {
    await pumpForAiModel(tester);

    expect(find.text('AI model'), findsOneWidget);
    expect(find.text('Gemini 3.8 Flash'), findsOneWidget);
  });

  testWidgets('the AI model row inks on the card and is tall enough to tap', (
    tester,
  ) async {
    await pumpForAiModel(tester);
    final row = find
        .ancestor(of: find.text('AI model'), matching: find.byType(InkWell))
        .first;
    final inkSurface = tester.widget<Material>(
      find.ancestor(of: row, matching: find.byType(Material)).first,
    );

    expect(inkSurface.type, MaterialType.transparency);
    expect(
      tester.getSize(row).height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
  });

  testWidgets('choosing another model saves it', (tester) async {
    final profile = await pumpForAiModel(tester);

    await chooseModel(tester, 'Gemini 3.1 Pro');

    expect(profile.updatedAiModels, [AiModel.geminiPro]);
  });

  testWidgets('keeping the current model saves nothing', (tester) async {
    final profile = await pumpForAiModel(tester);

    await chooseModel(tester, 'Gemini 3.8 Flash');

    expect(profile.updatedAiModels, isEmpty);
  });

  testWidgets('a failed save shows a message', (tester) async {
    final profile = await pumpForAiModel(tester);
    profile.aiModelError = const NetworkFailure();

    await chooseModel(tester, 'Gemini 3.5 Flash-Lite');

    expect(find.text(const NetworkFailure().message), findsOneWidget);
  });
}
