import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/tag_badge.dart';
import '../../../profile/application/services/body_metrics.dart';
import '../../../profile/application/services/profile_rules.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import '../../application/services/greeting.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider).value;
    final details = profile?.details;
    if (profile == null || details == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colors = context.colors;
    final text = context.textStyles;
    final bmi = calculateBmi(
      weightKg: details.weightKg,
      heightCm: details.heightCm,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingFor(DateTime.now()),
                      style: text.bodySmall.copyWith(color: colors.muted),
                    ),
                    Text(profile.displayName ?? 'there', style: text.subtitle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            HeroCard(
              badge: const TagBadge(label: 'Your profile'),
              title: details.goal.label,
              meta: '${details.level.label} · ${details.daysPerWeek} days/week',
              watermark: details.daysPerWeek.toString().padLeft(2, '0'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${ProfileRules.formatDecimal(details.weightKg)} kg',
                    label: 'Weight',
                    highlighted: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: '${ProfileRules.formatDecimal(details.heightCm)} cm',
                    label: 'Height',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: ProfileRules.formatDecimal(bmi),
                    label: 'BMI',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
