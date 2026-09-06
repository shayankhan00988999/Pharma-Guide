import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A slowly drifting, colorful gradient backdrop. Cheap to run (just an
/// animated Alignment) but reads as "alive" instead of a flat color.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({super.key, required this.child});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.6, -1),
              end: Alignment(1, 1 - t * 0.6),
              colors: const [
                AppColors.night,
                AppColors.night2,
                AppColors.purple,
                AppColors.teal,
              ],
              stops: const [0.0, 0.4, 0.75, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          _blob(top: -60, left: -40, color: AppColors.tealLight, size: 220),
          _blob(bottom: -50, right: -30, color: AppColors.purpleLight, size: 260),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.18),
        ),
      ),
    );
  }
}
