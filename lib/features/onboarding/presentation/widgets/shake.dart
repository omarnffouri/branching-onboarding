import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short horizontal shake each time [shakes] increases.
class Shake extends StatelessWidget {
  const Shake({required this.shakes, required this.child, super.key});

  final int shakes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakes == 0 || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shakes),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 4) * 8 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}
