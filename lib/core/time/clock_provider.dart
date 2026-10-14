import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;
