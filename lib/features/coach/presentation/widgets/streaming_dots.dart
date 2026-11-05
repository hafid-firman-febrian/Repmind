import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

class StreamingDots extends StatefulWidget {
  const StreamingDots({super.key});

  @override
  State<StreamingDots> createState() => _StreamingDotsState();
}

class _StreamingDotsState extends State<StreamingDots>
    with SingleTickerProviderStateMixin {
  static const _count = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacity(int index) {
    if (!_controller.isAnimating) return 1 - index * 0.3;
    final phase = (_controller.value - index / _count) % 1.0;
    return 1 - phase * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors.violet;

    return Semantics(
      label: 'Coach is typing',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _count; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: _opacity(i)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
