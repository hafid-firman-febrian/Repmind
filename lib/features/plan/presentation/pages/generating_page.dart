import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/repmind_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../controllers/plan_generation_controller.dart';
import '../states/plan_generation_state.dart';

class GeneratingPage extends ConsumerStatefulWidget {
  const GeneratingPage({super.key});

  static const statuses = [
    'Reading your profile',
    'Picking exercises for your equipment',
    'Balancing your week',
    'Checking every exercise',
  ];
  static const statusInterval = Duration(milliseconds: 2500);

  @override
  ConsumerState<GeneratingPage> createState() => _GeneratingPageState();
}

class _GeneratingPageState extends ConsumerState<GeneratingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  Timer? _statusTimer;
  var _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStatusTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(planGenerationControllerProvider) is PlanGenerationIdle) {
        context.go(AppRoutes.plan);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse
        ..stop()
        ..value = 1;
    } else if (!_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusIndex = 0;
    _statusTimer = Timer.periodic(
      GeneratingPage.statusInterval,
      (_) => _advanceStatus(),
    );
  }

  void _advanceStatus() {
    if (_statusIndex >= GeneratingPage.statuses.length - 1) {
      _statusTimer?.cancel();
      return;
    }
    setState(() => _statusIndex++);
  }

  void _finish() {
    ref.read(planGenerationControllerProvider.notifier).reset();
    context.go(AppRoutes.plan);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      _finish();
    }
  }

  String? _contextLine() {
    final profile = ref.watch(profileControllerProvider).value;
    final details = profile?.details;
    if (profile == null || details == null) return null;
    return '${details.daysPerWeek} days · ${details.goal.label} · ${profile.aiModel.label}';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(planGenerationControllerProvider, (previous, next) {
      if (next is PlanGenerationSucceeded) _finish();
      if (next is PlanGenerationRunning && previous is PlanGenerationFailed) {
        setState(_startStatusTimer);
      }
    });
    final state = ref.watch(planGenerationControllerProvider);
    final controller = ref.read(planGenerationControllerProvider.notifier);

    return PopScope(
      canPop: state is! PlanGenerationRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop &&
            ref.read(planGenerationControllerProvider) is! PlanGenerationIdle) {
          controller.reset();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: switch (state) {
                PlanGenerationRunning(:final instruction) => _RunningView(
                  adjusting: instruction != null,
                  status: GeneratingPage.statuses[_statusIndex],
                  contextLine: _contextLine(),
                  pulse: _pulse,
                ),
                PlanGenerationFailed(:final error) => _FailedView(
                  message: error.message,
                  onRetry: controller.retry,
                  onBack: _leave,
                ),
                PlanGenerationIdle() ||
                PlanGenerationSucceeded() => const SizedBox.shrink(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningView extends StatelessWidget {
  const _RunningView({
    required this.adjusting,
    required this.status,
    required this.contextLine,
    required this.pulse,
  });

  final bool adjusting;
  final String status;
  final String? contextLine;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final contextLine = this.contextLine;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween<double>(
            begin: 0.94,
            end: 1,
          ).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colors.violet,
              borderRadius: BorderRadius.circular(RepmindRadius.hero),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: colors.onViolet,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          adjusting ? 'ADJUSTING YOUR PLAN' : 'BUILDING YOUR PLAN',
          textAlign: TextAlign.center,
          style: text.title,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(status),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.violet),
              const SizedBox(width: 6),
              Flexible(child: Text(status, style: text.body)),
            ],
          ),
        ),
        if (contextLine != null) ...[
          const SizedBox(height: 10),
          Text(
            contextLine,
            textAlign: TextAlign.center,
            style: text.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: colors.danger),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textStyles.body,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Try again',
          variant: PrimaryButtonVariant.ai,
          onPressed: onRetry,
        ),
        const SizedBox(height: 12),
        SecondaryButton(label: 'Back', onPressed: onBack),
      ],
    );
  }
}
