import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/theme/repmind_theme.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';
import 'package:repmind/features/profile/presentation/pages/edit_profile_page.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';

class _AfterProfileLoads extends ConsumerWidget {
  const _AfterProfileLoads({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(profileControllerProvider).hasValue
      ? child
      : const SizedBox.shrink();
}

void main() {
  testWidgets('a failed save shows its message and keeps the page', (
    tester,
  ) async {
    final profile = FakeProfileController(sampleProfile())
      ..saveError = const NetworkFailure();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileControllerProvider.overrideWith(() => profile)],
        retry: (_, _) => null,
        child: MaterialApp(
          theme: buildRepmindTheme(),
          home: const _AfterProfileLoads(child: EditProfilePage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump();

    expect(find.text(const NetworkFailure().message), findsOneWidget);
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(profile.savedDetails, isEmpty);
  });

  testWidgets('a successful save confirms and closes the page', (tester) async {
    final profile = FakeProfileController(sampleProfile());
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(path: '/edit', builder: (_, _) => const EditProfilePage()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileControllerProvider.overrideWith(() => profile)],
        retry: (_, _) => null,
        child: _AfterProfileLoads(
          child: MaterialApp.router(
            theme: buildRepmindTheme(),
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    unawaited(router.push('/edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(profile.savedDetails, hasLength(1));
    expect(find.byType(EditProfilePage), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
  });
}
