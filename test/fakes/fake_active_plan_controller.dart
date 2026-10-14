import 'package:repmind/features/plan/domain/models/workout_plan_model.dart';
import 'package:repmind/features/plan/presentation/controllers/active_plan_controller.dart';

class FakeActivePlanController extends ActivePlanController {
  FakeActivePlanController(this.initial, {this.loadError});

  final WorkoutPlan? initial;
  final Object? loadError;

  @override
  Future<WorkoutPlan?> build() async {
    final error = loadError;
    if (error != null) throw error;
    return initial;
  }
}
