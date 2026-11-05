import 'plan_proposal_model.dart';

enum ChatRole {
  user('user'),
  assistant('assistant');

  const ChatRole(this.dbValue);

  final String dbValue;

  static ChatRole fromDb(String value) =>
      values.firstWhere((role) => role.dbValue == value);
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.proposal,
    this.appliedPlanId,
    this.appliedPlanVersion,
  });

  final String id;
  final ChatRole role;
  final String content;
  final PlanProposal? proposal;
  final String? appliedPlanId;
  final int? appliedPlanVersion;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final proposal = json['proposal'] as Map<String, dynamic>?;
    final appliedPlan = json['applied_plan'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.fromDb(json['role'] as String),
      content: json['content'] as String,
      proposal: proposal == null ? null : PlanProposal.fromJson(proposal),
      appliedPlanId: json['applied_plan_id'] as String?,
      appliedPlanVersion: appliedPlan?['version'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ChatMessage copyWith({
    String? id,
    String? appliedPlanId,
    int? appliedPlanVersion,
  }) => ChatMessage(
    id: id ?? this.id,
    role: role,
    content: content,
    proposal: proposal,
    appliedPlanId: appliedPlanId ?? this.appliedPlanId,
    appliedPlanVersion: appliedPlanVersion ?? this.appliedPlanVersion,
    createdAt: createdAt,
  );
}
