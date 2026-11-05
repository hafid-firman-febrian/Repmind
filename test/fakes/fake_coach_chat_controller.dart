import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/coach/presentation/controllers/coach_chat_controller.dart';
import 'package:repmind/features/coach/presentation/states/coach_chat_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class FakeCoachChatController extends CoachChatController {
  FakeCoachChatController([this.initial = const CoachChatState()]);

  final CoachChatState initial;
  final sendCalls = <String>[];
  final applyCalls = <String>[];
  var retryCalls = 0;
  var clearAutoReviewCalls = 0;
  AppException? applyError;

  @override
  Future<CoachChatState> build() async => initial;

  @override
  Future<void> send(String text) async {
    sendCalls.add(text);
  }

  @override
  Future<void> retry() async {
    retryCalls++;
  }

  @override
  Future<void> applyProposal(String messageId) async {
    applyCalls.add(messageId);
    final error = applyError;
    if (error != null) throw error;
  }

  @override
  void clearAutoReview() {
    clearAutoReviewCalls++;
  }

  void emit(CoachChatState next) => state = AsyncData(next);
}
