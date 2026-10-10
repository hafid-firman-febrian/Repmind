import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/models/auth_status.dart';

part 'auth_status_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<AuthStatus> authStatus(Ref ref) =>
    ref.watch(authRepositoryProvider).authStatusChanges();

@Riverpod(keepAlive: true)
String? currentUserId(Ref ref) {
  ref.watch(authStatusProvider);
  return ref.watch(authRepositoryProvider).currentUserId;
}
