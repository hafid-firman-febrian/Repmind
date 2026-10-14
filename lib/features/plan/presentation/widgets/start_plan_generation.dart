import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../controllers/plan_generation_controller.dart';
import '../states/plan_generation_state.dart';

void startPlanGeneration(
  BuildContext context,
  WidgetRef ref, {
  String? instruction,
}) {
  if (ref.read(planGenerationControllerProvider) is PlanGenerationRunning) {
    return;
  }
  ref
      .read(planGenerationControllerProvider.notifier)
      .generate(instruction: instruction);
  context.push(AppRoutes.generating);
}
