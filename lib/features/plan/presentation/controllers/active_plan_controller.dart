import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/controllers/auth_status_provider.dart';
import '../../data/repositories/plan_repository.dart';
import '../../domain/models/workout_plan_model.dart';

part 'active_plan_controller.g.dart';

@Riverpod(keepAlive: true)
class ActivePlanController extends _$ActivePlanController {
  @override
  Future<WorkoutPlan?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.watch(planRepositoryProvider).fetchActivePlan(userId);
  }
}
