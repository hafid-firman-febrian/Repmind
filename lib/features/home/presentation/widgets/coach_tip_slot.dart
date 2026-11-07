import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/coach_tip_card.dart';
import '../../../coach/presentation/controllers/coach_tip_controller.dart';

class CoachTipSlot extends ConsumerWidget {
  const CoachTipSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tip = ref.watch(coachTipControllerProvider).value;
    if (tip == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CoachTipCard(text: tip, onTap: () => context.go(AppRoutes.coach)),
    );
  }
}
