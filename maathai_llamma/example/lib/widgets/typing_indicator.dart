import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing_md,
          vertical: AppTheme.spacing_sm,
        ),
        margin: const EdgeInsets.only(
          left: 0,
          right: AppTheme.spacing_xl,
          bottom: AppTheme.spacing_sm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = (_controller.value + i / 3.0) % 1.0;
                final dy = (t < 0.5) ? (t * 2.0) : (2.0 - t * 2.0);
                final scale = 0.7 + 0.3 * dy;
                return Container(
                  margin: EdgeInsets.only(
                    right: i == 2 ? 0 : AppTheme.spacing_xs,
                  ),
                  width: 8,
                  height: 8,
                  transform: Matrix4.identity()..scale(scale),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}


