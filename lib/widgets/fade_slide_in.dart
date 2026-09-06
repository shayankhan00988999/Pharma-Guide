import 'package:flutter/material.dart';

/// Fades and slides its child up into place once, on first build.
/// Used to stagger-in the auth screens and dashboard sections instead
/// of everything just snapping into view.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offsetY = 24,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Hold at 0 for the delay portion, then ease in.
        final delayFraction =
            delay.inMilliseconds / (duration + delay).inMilliseconds;
        final adjusted = delayFraction >= 1
            ? 0.0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - adjusted)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
