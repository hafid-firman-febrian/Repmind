import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/repmind_decorations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_snack_bar.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenForAuthSnackBar(context, ref);
    final colors = context.colors;
    final text = context.textStyles;
    final profile = ref.watch(profileControllerProvider);
    final error = profile.error;
    final errorMessage = profile.isLoading || error == null
        ? null
        : mapToAppException(error).message;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: RepmindDecorations.limeHero(colors),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 52,
                    color: colors.violet,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('REPMIND', style: text.headline),
              const SizedBox(height: 28),
              if (errorMessage == null)
                const CircularProgressIndicator()
              else ...[
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: text.body.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Try again',
                  onPressed: () => ref.invalidate(profileControllerProvider),
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Sign out',
                  isLoading: ref.watch(authControllerProvider).isLoading,
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
