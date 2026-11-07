import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../plan/presentation/controllers/active_plan_controller.dart';
import '../../application/services/coach_tip_date.dart';
import '../../data/repositories/coach_repository.dart';

part 'coach_tip_controller.g.dart';

const _retryDelay = Duration(seconds: 60);

@Riverpod(keepAlive: true)
class CoachTipController extends _$CoachTipController {
  final _retried = <String>{};
  Timer? _retryTimer;

  @override
  Future<String?> build() async {
    ref.onDispose(() {
      _retryTimer?.cancel();
      _retryTimer = null;
    });
    String? attempt;
    try {
      final plan = await ref.watch(activePlanControllerProvider.future);
      if (plan == null || !ref.mounted) return null;
      final repository = ref.read(coachRepositoryProvider);
      final now = ref.read(clockProvider)();
      final date = formatTipDate(now);
      attempt = '${plan.id}|$date';
      final saved = await repository.fetchTip(planId: plan.id, date: date);
      if (saved != null) return saved;
      if (!ref.mounted) return null;
      return await repository.generateTip(date: date, weekday: now.weekday);
    } catch (_) {
      if (attempt != null && ref.mounted && _retried.add(attempt)) {
        _retryTimer = Timer(_retryDelay, ref.invalidateSelf);
      }
      return null;
    }
  }
}
