import 'package:supabase_flutter/supabase_flutter.dart';

class PlanRemoteDataSource {
  PlanRemoteDataSource(
    this._client, {
    this.generateTimeout = const Duration(seconds: 150),
  });

  static const _activePlanQuery =
      '*, plan_days(*, plan_exercises(*, exercises(*)))';

  final SupabaseClient _client;
  final Duration generateTimeout;

  Future<Map<String, dynamic>?> fetchActivePlan(String userId) => _client
      .from('workout_plans')
      .select(_activePlanQuery)
      .eq('user_id', userId)
      .isFilter('archived_at', null)
      .maybeSingle();

  Future<String> generatePlan({String? instruction}) async {
    final response = await _client.functions
        .invoke('generate-plan', body: {'instruction': ?instruction})
        .timeout(generateTimeout);
    final data = response.data as Map<String, dynamic>;
    return data['plan_id'] as String;
  }
}
