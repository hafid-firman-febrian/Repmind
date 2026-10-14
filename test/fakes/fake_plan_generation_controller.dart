import 'package:repmind/features/plan/presentation/controllers/plan_generation_controller.dart';
import 'package:repmind/features/plan/presentation/states/plan_generation_state.dart';

class FakePlanGenerationController extends PlanGenerationController {
  FakePlanGenerationController([this.initial = const PlanGenerationIdle()]);

  final PlanGenerationState initial;
  final generateCalls = <String?>[];
  var retryCalls = 0;

  @override
  PlanGenerationState build() => initial;

  @override
  Future<void> generate({String? instruction}) async {
    generateCalls.add(instruction);
  }

  @override
  Future<void> retry() async {
    retryCalls++;
  }

  void emit(PlanGenerationState next) => state = next;
}
