import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';

/// Soft colour drifting slowly behind a screen, like water finding its way:
/// a quiet nod to lymphatic *flow*.
///
/// Painted with radial gradients rather than blur filters, driven by one
/// repeating ticker, isolated in its own layer, and perfectly still when
/// the system asks for reduced motion.
class FlowBackground extends StatefulWidget {
  const FlowBackground({
    this.child,
    this.colors,
    this.strength = 0.75,
    super.key,
  });

  final Widget? child;

  /// Three colours for the drifting shapes; the soft pastels by default.
  final List<Color>? colors;

  /// Opacity at the centre of each shape.
  final double strength;

  @override
  State<FlowBackground> createState() => _FlowBackgroundState();
}

class _FlowBackgroundState extends State<FlowBackground>
    with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      unawaited(_drift.repeat());
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _FlowPainter(
        _drift,
        widget.colors ??
            const [
              AppColors.flowRose,
              AppColors.flowPeach,
              AppColors.flowLilac,
            ],
        widget.strength,
      ),
      child: widget.child ?? const SizedBox.expand(),
    ),
  );
}

/// One drifting shape. Frequencies are whole numbers so the loop is seamless.
typedef _Blob = ({
  double x,
  double y,
  double radius,
  double driftX,
  double driftY,
  int speed,
  double phase,
});

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.t, this.colors, this.strength) : super(repaint: t);

  final Animation<double> t;
  final List<Color> colors;
  final double strength;

  static const List<_Blob> _blobs = [
    (
      x: 0.85,
      y: 0.12,
      radius: 0.75,
      driftX: 0.10,
      driftY: 0.06,
      speed: 1,
      phase: 0,
    ),
    (
      x: 0.1,
      y: 0.78,
      radius: 0.8,
      driftX: 0.08,
      driftY: 0.08,
      speed: 1,
      phase: 2.1,
    ),
    (
      x: 0.55,
      y: 0.45,
      radius: 0.55,
      driftX: 0.14,
      driftY: 0.1,
      speed: 2,
      phase: 4.2,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t.value * 2 * math.pi;
    for (final (i, blob) in _blobs.indexed) {
      final color = colors[i % colors.length];
      final center = Offset(
        size.width *
            (blob.x + blob.driftX * math.sin(angle * blob.speed + blob.phase)),
        size.height *
            (blob.y + blob.driftY * math.cos(angle * blob.speed + blob.phase)),
      );
      final radius = size.width * blob.radius;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: strength),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_FlowPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.colors != colors ||
      oldDelegate.strength != strength;
}
