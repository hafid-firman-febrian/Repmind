import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/time/clock_provider.dart';

void main() {
  test('reads the device clock by default', () {
    final container = ProviderContainer.test();
    final before = DateTime.now();

    final now = container.read(clockProvider)();

    expect(now.isBefore(before), isFalse);
  });

  test('can be replaced with a fixed clock', () {
    final fixed = DateTime(2026, 10, 13, 9);
    final container = ProviderContainer.test(
      overrides: [clockProvider.overrideWithValue(() => fixed)],
    );

    expect(container.read(clockProvider)(), fixed);
  });
}
