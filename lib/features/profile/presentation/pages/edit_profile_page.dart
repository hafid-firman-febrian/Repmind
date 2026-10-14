import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/square_icon_button.dart';
import '../controllers/edit_profile_controller.dart';
import '../widgets/body_metrics_fields.dart';
import '../widgets/goal_selector.dart';
import '../widgets/level_selector.dart';
import '../widgets/schedule_equipment_fields.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final saved = await ref.read(editProfileControllerProvider.notifier).save();
    if (!saved || !context.mounted) return;
    showAppSnackBar(context, 'Profile updated');
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(editProfileControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) return;
      showAppSnackBar(context, error.message);
    });

    final state = ref.watch(editProfileControllerProvider);
    final controller = ref.read(editProfileControllerProvider.notifier);
    final colors = context.colors;
    final text = context.textStyles;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: text.section.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cancel',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Text('EDIT DETAILS', style: text.title),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  section(
                    'Goal',
                    GoalSelector(
                      draft: state.draft,
                      onChanged: controller.updateDraft,
                    ),
                  ),
                  section(
                    'Level',
                    LevelSelector(
                      draft: state.draft,
                      onChanged: controller.updateDraft,
                    ),
                  ),
                  section(
                    'Schedule & equipment',
                    ScheduleEquipmentFields(
                      draft: state.draft,
                      onChanged: controller.updateDraft,
                    ),
                  ),
                  section(
                    'Body',
                    BodyMetricsFields(
                      draft: state.draft,
                      onChanged: controller.updateDraft,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PrimaryButton(
                label: 'Save changes',
                isLoading: state.isSubmitting,
                onPressed: state.draft.toDetails() == null
                    ? null
                    : () => _save(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
