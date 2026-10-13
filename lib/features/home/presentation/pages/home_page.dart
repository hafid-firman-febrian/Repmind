import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/widgets/loading_scaffold.dart';
import '../../../plan/presentation/widgets/active_plan_section.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../application/services/greeting.dart';
import '../widgets/this_week_card.dart';
import '../widgets/today_workout_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    if (profile == null || profile.details == null) {
      return const LoadingScaffold();
    }

    final now = ref.watch(clockProvider)();
    final colors = context.colors;
    final text = context.textStyles;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.profile),
                  child: Semantics(
                    button: true,
                    label: 'Open profile',
                    child: ProfileAvatar(
                      imageUrl: profile.avatarUrl,
                      name: profile.displayName,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingFor(now).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.label.copyWith(color: colors.muted),
                      ),
                      Text(
                        profile.displayName ?? 'there',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.subtitle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ActivePlanSection(
              builder: (context, plan) => Column(
                children: [
                  TodayWorkoutCard(plan: plan, now: now),
                  const SizedBox(height: 12),
                  ThisWeekCard(plan: plan, now: now),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
