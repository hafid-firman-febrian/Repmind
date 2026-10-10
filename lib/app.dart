import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/repmind_theme.dart';

class RepmindApp extends ConsumerWidget {
  const RepmindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Repmind',
    debugShowCheckedModeBanner: false,
    theme: buildRepmindTheme(),
    routerConfig: ref.watch(appRouterProvider),
  );
}
