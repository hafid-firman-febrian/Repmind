import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repmind/features/auth/data/repositories/auth_repository.dart';
import 'package:repmind/features/auth/domain/models/auth_status.dart';
import 'package:repmind/features/auth/presentation/controllers/auth_status_provider.dart';

import '../../../helpers/mocks.dart';

void main() {
  test('currentUserId follows auth changes', () async {
    final repository = MockAuthRepository();
    final statuses = StreamController<AuthStatus>();
    addTearDown(statuses.close);
    String? userId;
    when(
      () => repository.authStatusChanges(),
    ).thenAnswer((_) => statuses.stream);
    when(() => repository.currentUserId).thenAnswer((_) => userId);

    final container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
    );
    container.listen(currentUserIdProvider, (_, _) {});

    expect(container.read(currentUserIdProvider), isNull);

    userId = 'user-1';
    statuses.add(AuthStatus.signedIn);
    await container.read(authStatusProvider.future);

    expect(container.read(currentUserIdProvider), 'user-1');
  });
}
