import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/secondary_button.dart';
import '../controllers/auth_controller.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return SecondaryButton(
      label: 'Continue with Google',
      icon: Icons.g_mobiledata_rounded,
      onPressed: isLoading
          ? null
          : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
    );
  }
}
