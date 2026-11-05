import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';
import '../../../plan/presentation/controllers/active_plan_controller.dart';
import '../../application/services/coach_tip_date.dart';
import '../../data/repositories/coach_repository.dart';

part 'coach_tip_controller.g.dart';

@Riverpod(keepAlive: true)
class CoachTipController extends _$CoachTipController {
  @override
  Future<String?> build() async {
    try {
      final plan = await ref.watch(activePlanControllerProvider.future);
      if (plan == null || !ref.mounted) return null;
      final repository = ref.read(coachRepositoryProvider);
      final now = ref.read(clockProvider)();
      final date = formatTipDate(now);
      final saved = await repository.fetchTip(planId: plan.id, date: date);
      if (saved != null) return saved;
      if (!ref.mounted) return null;
      return await repository.generateTip(date: date, weekday: now.weekday);
    } catch (_) {
      return null;
    }
  }
}
