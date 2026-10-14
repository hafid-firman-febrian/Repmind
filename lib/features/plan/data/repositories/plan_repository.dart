import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../domain/models/workout_plan_model.dart';
import '../data_sources/plan_remote_data_source.dart';

part 'plan_repository.g.dart';

class PlanRepository {
  PlanRepository(this._remote);

  final PlanRemoteDataSource _remote;

  Future<WorkoutPlan?> fetchActivePlan(String userId) => runGuarded(() async {
    final row = await _remote.fetchActivePlan(userId);
    return row == null ? null : WorkoutPlan.fromJson(row);
  });

  Future<String> generatePlan({String? instruction}) =>
      runGuarded(() => _remote.generatePlan(instruction: instruction));
}

@Riverpod(keepAlive: true)
PlanRepository planRepository(Ref ref) =>
    PlanRepository(PlanRemoteDataSource(ref.watch(supabaseClientProvider)));
