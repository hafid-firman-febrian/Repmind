import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/loading_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_snack_bar.dart';
import '../../application/services/profile_rules.dart';
import '../controllers/avatar_upload_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(avatarUploadControllerProvider, (_, next) {
      final error = next.error;
      if (next.isLoading || error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(mapToAppException(error).message)),
        );
    });
    listenForAuthSnackBar(context, ref);

    final profile = ref.watch(profileControllerProvider).value;
    final details = profile?.details;
    if (profile == null || details == null) return const LoadingScaffold();

    final colors = context.colors;
    final text = context.textStyles;
    final isUploading = ref.watch(avatarUploadControllerProvider).isLoading;
    final isSigningOut = ref.watch(authControllerProvider).isLoading;
    final pickPhoto = isUploading
        ? null
        : () =>
              ref.read(avatarUploadControllerProvider.notifier).pickAndUpload();
    final equipment = details.equipment.isEmpty
        ? 'Bodyweight only'
        : details.equipment.map((item) => item.label).join(', ');

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SquareIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  Semantics(
                    button: true,
                    label: 'Change photo',
                    child: GestureDetector(
                      onTap: pickPhoto,
                      child: ExcludeSemantics(
                        child: ProfileAvatar(
                          imageUrl: profile.avatarUrl,
                          name: profile.displayName,
                          size: 104,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Tooltip(
                      message: 'Change photo',
                      child: Material(
                        color: colors.ink,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: pickPhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: isUploading
                                ? SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.surface,
                                    ),
                                  )
                                : Icon(
                                    Icons.photo_camera_rounded,
                                    size: 18,
                                    color: colors.surface,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                (profile.displayName ?? 'Your profile').toUpperCase(),
                style: text.title,
              ),
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(RepmindRadius.card),
                border: Border.all(color: colors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Goal', value: details.goal.label),
                    _DetailRow(label: 'Level', value: details.level.label),
                    _DetailRow(
                      label: 'Schedule',
                      value: '${details.daysPerWeek} days/week',
                    ),
                    _DetailRow(label: 'Equipment', value: equipment),
                    _DetailRow(
                      label: 'Weight',
                      value: ProfileRules.formatWeight(details.weightKg),
                    ),
                    _DetailRow(
                      label: 'Height',
                      value: ProfileRules.formatHeight(details.heightCm),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Edit details',
              onPressed: () => context.push(AppRoutes.editProfile),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Sign out',
              destructive: true,
              isLoading: isSigningOut,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: text.body.copyWith(color: context.colors.muted),
            ),
          ),
          Expanded(child: Text(value, style: text.body)),
        ],
      ),
    );
  }
}
