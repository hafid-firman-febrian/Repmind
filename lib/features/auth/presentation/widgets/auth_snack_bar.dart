import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

void listenForAuthSnackBar(BuildContext context, WidgetRef ref) {
  ref.listen(authControllerProvider, (_, next) {
    final message = authSnackBarError(next);
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  });
}
