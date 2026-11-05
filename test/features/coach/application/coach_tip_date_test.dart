import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/coach/application/services/coach_tip_date.dart';

void main() {
  test('formats the date as yyyy-MM-dd with zero padding', () {
    expect(formatTipDate(DateTime(2026, 11, 5, 9)), '2026-11-05');
    expect(formatTipDate(DateTime(2026, 1, 9)), '2026-01-09');
    expect(formatTipDate(DateTime(2026, 12, 31, 23, 59)), '2026-12-31');
  });
}
