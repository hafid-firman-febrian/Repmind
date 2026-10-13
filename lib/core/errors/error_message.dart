import 'app_exception.dart';

String messageOf(Object error) =>
    error is AppException ? error.message : const UnknownFailure().message;
