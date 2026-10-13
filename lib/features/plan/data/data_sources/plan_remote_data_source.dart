import 'package:supabase_flutter/supabase_flutter.dart';

class PlanRemoteDataSource {
  PlanRemoteDataSource(this._client);

  static const _activePlanQuery =
      '*, plan_days(*, plan_exercises(*, exercises(*)))';

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchActivePlan(String userId) => _client
      .from('workout_plans')
      .select(_activePlanQuery)
      .eq('user_id', userId)
      .isFilter('archived_at', null)
      .maybeSingle();

  Future<String> generatePlan({String? instruction}) async {
    final response = await _client.functions.invoke(
      'generate-plan',
      body: {'instruction': ?instruction},
    );
    final data = response.data as Map<String, dynamic>;
    return data['plan_id'] as String;
  }
}
