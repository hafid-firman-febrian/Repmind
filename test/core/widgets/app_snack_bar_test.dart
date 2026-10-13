import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/widgets/app_snack_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the message and replaces the previous snack bar', (
    tester,
  ) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            TextButton(
              onPressed: () => showAppSnackBar(context, 'First'),
              child: const Text('one'),
            ),
            TextButton(
              onPressed: () => showAppSnackBar(context, 'Second'),
              child: const Text('two'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('one'));
    await tester.pump();
    expect(find.text('First'), findsOneWidget);

    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });
}
