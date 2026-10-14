import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/core/errors/error_message.dart';

void main() {
  test('uses the AppException message', () {
    expect(messageOf(const NetworkFailure()), const NetworkFailure().message);
  });

  test('falls back to the generic message for anything else', () {
    expect(messageOf(StateError('bug')), const UnknownFailure().message);
  });
}
