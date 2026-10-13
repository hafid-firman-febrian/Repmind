import '../../../../core/errors/app_exception.dart';

sealed class PlanGenerationState {
  const PlanGenerationState();
}

final class PlanGenerationIdle extends PlanGenerationState {
  const PlanGenerationIdle();
}

final class PlanGenerationRunning extends PlanGenerationState {
  const PlanGenerationRunning({this.instruction});

  final String? instruction;
}

final class PlanGenerationSucceeded extends PlanGenerationState {
  const PlanGenerationSucceeded();
}

final class PlanGenerationFailed extends PlanGenerationState {
  const PlanGenerationFailed(this.error, {this.instruction});

  final AppException error;
  final String? instruction;
}
