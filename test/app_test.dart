import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/app.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/auth/domain/models/auth_status.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';
import 'package:repmind/features/auth/presentation/pages/splash_page.dart';
import 'package:repmind/features/auth/presentation/pages/welcome_page.dart';
import 'package:repmind/features/profile/domain/models/profile_model.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import 'fakes/fake_profile_controller.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required Stream<AuthStatus> auth,
    required FakeProfileController profile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authStatusProvider.overrideWith((ref) => auth),
          profileControllerProvider.overrideWith(() => profile),
        ],
        child: const RepmindApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows Splash while the session is being restored', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: const Stream.empty(),
      profile: FakeProfileController(null),
    );

    expect(find.byType(SplashPage), findsOneWidget);
  });

  testWidgets('signed-out users land on Welcome', (tester) async {
    await pumpApp(
      tester,
      auth: Stream.value(AuthStatus.signedOut),
      profile: FakeProfileController(null),
    );

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('offers a retry when the profile cannot be loaded', (
    tester,
  ) async {
    await pumpApp(
      tester,
      auth: Stream.value(AuthStatus.signedIn),
      profile: FakeProfileController(null, loadError: const NetworkFailure()),
    );

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  testWidgets('shows the spinner instead of the error while retrying', (
    tester,
  ) async {
    final profile = ReloadingProfileController();
    await pumpApp(
      tester,
      auth: Stream.value(AuthStatus.signedIn),
      profile: profile,
    );
    expect(find.text(const NetworkFailure().message), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Try again'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(const NetworkFailure().message), findsNothing);
  });
}

class ReloadingProfileController extends FakeProfileController {
  ReloadingProfileController() : super(null);

  final reload = Completer<Profile?>();
  var loads = 0;

  @override
  Future<Profile?> build() {
    loads++;
    if (loads == 1) throw const NetworkFailure();
    return reload.future;
  }
}
