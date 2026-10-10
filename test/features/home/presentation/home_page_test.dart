import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/home/presentation/pages/home_page.dart';
import 'package:repmind/features/profile/presentation/controllers/profile_controller.dart';

import '../../../fakes/fake_profile_controller.dart';
import '../../../fixtures/profile_fixtures.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('summarizes the profile with body stats', (tester) async {
    await pumpPage(
      tester,
      const HomePage(),
      overrides: [
        profileControllerProvider.overrideWith(
          () => FakeProfileController(sampleProfile()),
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('BUILD MUSCLE'), findsOneWidget);
    expect(find.text('Intermediate · 4 days/week'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.text('23.7'), findsOneWidget);
  });
}
