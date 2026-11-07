import 'package:supabase_flutter/supabase_flutter.dart';

class CoachRemoteDataSource {
  CoachRemoteDataSource(this._client);

  static const _messagesQuery =
      '*, applied_plan:workout_plans!chat_messages_applied_plan_id_fkey(version)';
  static const _messageLimit = 50;

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchMessages(String userId) async {
    final rows = await _client
        .from('chat_messages')
        .select(_messagesQuery)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(_messageLimit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Stream<List<int>>> openReply(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke('coach-chat', body: body);
    return response.data as Stream<List<int>>;
  }

  Future<String> applyProposal(String messageId) async {
    final planId = await _client.rpc(
      'apply_coach_proposal',
      params: {'p_message_id': messageId},
    );
    return planId as String;
  }

  Future<String?> fetchTip({
    required String planId,
    required String date,
  }) async {
    final row = await _client
        .from('coach_tips')
        .select('content')
        .eq('plan_id', planId)
        .eq('tip_date', date)
        .maybeSingle();
    return row?['content'] as String?;
  }

  Future<String> generateTip({
    required String date,
    required int weekday,
  }) async {
    final response = await _client.functions.invoke(
      'coach-tip',
      body: {'date': date, 'weekday': weekday},
    );
    final data = response.data as Map<String, dynamic>;
    return data['tip'] as String;
  }
}
