import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/theme/repmind_theme.dart';

Future<void> pumpThemed(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) => pumpPage(tester, Scaffold(body: child), overrides: overrides);

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  List<Override> overrides = const [],
}) => tester.pumpWidget(
  ProviderScope(
    overrides: overrides,
    retry: (_, _) => null,
    child: MaterialApp(theme: buildRepmindTheme(), home: page),
  ),
);
