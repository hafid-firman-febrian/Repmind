import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/features/auth/application/services/auth_validators.dart';

void main() {
  test('name must not be blank', () {
    expect(AuthValidators.name('  '), 'Enter your name.');
    expect(AuthValidators.name('Alex'), isNull);
  });

  test('email must look like an address, spaces allowed around it', () {
    expect(AuthValidators.email(''), 'Enter your email.');
    expect(AuthValidators.email('alex@'), 'Enter a valid email address.');
    expect(AuthValidators.email(' Alex@Mail.com '), isNull);
  });

  test('new passwords need at least 8 characters', () {
    expect(AuthValidators.password('1234567'), 'Use at least 8 characters.');
    expect(AuthValidators.password('12345678'), isNull);
  });

  test('sign-in password only needs to be present', () {
    expect(AuthValidators.signInPassword(''), 'Enter your password.');
    expect(AuthValidators.signInPassword('x'), isNull);
  });
}
