import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:repmind/core/theme/repmind_theme.dart';

Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required String initialLocation,
  required List<RouteBase> routes,
  List<Override> overrides = const [],
}) async {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp.router(
        theme: buildRepmindTheme(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  return router;
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
