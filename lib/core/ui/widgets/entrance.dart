import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

/// Fades and lifts [child] in as its page arrives, staggered by [index].
///
/// Driven by the route's own animation rather than a separate controller,
/// so the stagger is in lockstep with the page transition, plays in reverse
/// when she goes back, and never replays on a page she returns to.
class Entrance extends StatelessWidget {
  const Entrance({
    required this.index,
    required this.child,
    this.lift = 18,
    super.key,
  });

  final int index;
  final Widget child;

  /// How far, in logical pixels, the child rises into place.
  final double lift;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || MediaQuery.disableAnimationsOf(context)) return child;

    final start = (0.2 + index * 0.08).clamp(0.0, 0.7);
    final curve = CurveTween(
      curve: Interval(
        start,
        (start + 0.45).clamp(0.0, 1.0),
        curve: AppMotion.emphasized,
      ),
    );
    final progress = route.drive(curve);

    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => Opacity(
        opacity: progress.value,
        child: Transform.translate(
          offset: Offset(0, lift * (1 - progress.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
