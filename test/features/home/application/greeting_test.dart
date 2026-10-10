import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/home/application/services/greeting.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 9, 30, hour);

  test('morning from 05:00 to 11:59', () {
    expect(greetingFor(at(5)), 'Good morning');
    expect(greetingFor(at(11)), 'Good morning');
  });

  test('afternoon from 12:00 to 17:59', () {
    expect(greetingFor(at(12)), 'Good afternoon');
    expect(greetingFor(at(17)), 'Good afternoon');
  });

  test('evening otherwise', () {
    expect(greetingFor(at(18)), 'Good evening');
    expect(greetingFor(at(0)), 'Good evening');
    expect(greetingFor(at(4)), 'Good evening');
  });
}
