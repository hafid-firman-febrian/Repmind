import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/plan_repository.dart';
import '../states/plan_generation_state.dart';
import 'active_plan_controller.dart';

part 'plan_generation_controller.g.dart';

@Riverpod(keepAlive: true)
class PlanGenerationController extends _$PlanGenerationController {
  @override
  PlanGenerationState build() => const PlanGenerationIdle();

  Future<void> generate({String? instruction}) async {
    if (state is PlanGenerationRunning) return;
    state = PlanGenerationRunning(instruction: instruction);
    try {
      await ref
          .read(planRepositoryProvider)
          .generatePlan(instruction: instruction);
    } on AppException catch (error) {
      if (ref.mounted) {
        state = PlanGenerationFailed(error, instruction: instruction);
      }
      return;
    }
    await ref
        .refresh(activePlanControllerProvider.future)
        .then<void>((_) {}, onError: (Object _) {});
    if (ref.mounted) state = const PlanGenerationSucceeded();
  }

  Future<void> retry() async {
    final current = state;
    if (current is PlanGenerationFailed) {
      await generate(instruction: current.instruction);
    }
  }

  void reset() => state = const PlanGenerationIdle();
}
