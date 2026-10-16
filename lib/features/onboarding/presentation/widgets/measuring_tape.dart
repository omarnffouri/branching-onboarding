import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

/// Keeps the tape's drawing and direction handling out of the screen layout.
class MeasuringTape extends StatelessWidget {
  const MeasuringTape({
    required this.value,
    required this.min,
    required this.max,
    required this.spacing,
    required this.centerY,
    required this.radius,
    super.key,
  });

  final double value;
  final int min;
  final int max;
  final double spacing;
  final double centerY;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TapePainter(
      value: value,
      min: min,
      max: max,
      spacing: spacing,
      centerY: centerY,
      radius: radius,
      rtl: Directionality.of(context) == TextDirection.rtl,
    ),
  );
}

/// A cream measuring tape wrapped around a cylinder (her waist), seen from
/// the front: marks are spaced by the sine of their angle, so they bunch
/// up, shrink and fade as they turn away at the sides.
class _TapePainter extends CustomPainter {
  _TapePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.spacing,
    required this.centerY,
    required this.radius,
    required this.rtl,
  });

  final double value;
  final int min;
  final int max;
  final double spacing;
  final double centerY;
  final double radius;
  final bool rtl;

  static const _band = 40.0;
  static const _tapeColor = Color(0xFFFBF3E6);
  static const _markColor = Color(0xFF5B4A44);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final dir = rtl ? -1.0 : 1.0;

    // Where a point `s` pixels along the tape (from the front) lands, and
    // how much of it faces us.
    (double x, double y, double facing) project(double s) {
      final angle = (s / radius).clamp(-math.pi / 2, math.pi / 2);
      final x = cx + dir * radius * math.sin(angle);
      // A gentle smile curve: the tape sits lower at the front.
      final y = centerY - 10 * (1 - math.cos(angle));
      return (x, y, math.cos(angle));
    }

    // The band itself, as a ribbon following the curve.
    final top = Path();
    final bottom = <Offset>[];
    for (var s = -radius * 1.55; s <= radius * 1.55; s += 6) {
      final (x, y, _) = project(s);
      if (s == -radius * 1.55) {
        top.moveTo(x, y - _band / 2);
      } else {
        top.lineTo(x, y - _band / 2);
      }
      bottom.add(Offset(x, y + _band / 2));
    }
    for (final point in bottom.reversed) {
      top.lineTo(point.dx, point.dy);
    }
    top.close();
    canvas
      ..drawShadow(top, Colors.black, 3, false)
      ..drawPath(top, Paint()..color = _tapeColor)
      ..drawPath(
        top,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.18),
            ],
            stops: const [0, 0.2, 0.8, 1],
          ).createShader(Offset.zero & size),
      );

    // Marks and numbers that are currently on the visible side.
    final first = (value - radius * 1.6 / spacing).floor();
    final last = (value + radius * 1.6 / spacing).ceil();
    for (var unit = math.max(first, min); unit <= math.min(last, max); unit++) {
      final s = (unit - value) * spacing;
      if (s.abs() > radius * 1.55) continue;
      final (x, y, facing) = project(s);
      if (facing <= 0.05) continue;
      final opacity = facing.clamp(0.0, 1.0);
      final major = unit % 5 == 0;
      final length = (major ? 14.0 : 7.0) * (0.6 + 0.4 * facing);
      final mark = Paint()
        ..color = _markColor.withValues(alpha: opacity)
        ..strokeWidth = major ? 1.6 : 1;
      canvas.drawLine(
        Offset(x, y - _band / 2),
        Offset(x, y - _band / 2 + length),
        mark,
      );
      // Only every 5 cm is numbered, like a real tape: three-digit numbers
      // at every centimetre would collide.
      if (major) {
        final label = TextPainter(
          text: TextSpan(
            text: '$unit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11 * (0.7 + 0.3 * facing),
              fontWeight: FontWeight.w600,
              color: _markColor.withValues(alpha: opacity),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          Offset(x - label.width / 2, y + _band / 2 - label.height - 3),
        );
      }
    }

    // The fixed reading line at the front, in rose.
    final (fx, fy, _) = project(0);
    final needle = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        Offset(fx, fy - _band / 2 - 10),
        Offset(fx, fy + _band / 2 + 10),
        needle,
      )
      ..drawPath(
        Path()
          ..moveTo(fx - 7, fy - _band / 2 - 16)
          ..lineTo(fx + 7, fy - _band / 2 - 16)
          ..lineTo(fx, fy - _band / 2 - 7)
          ..close(),
        Paint()..color = AppColors.primary,
      );
  }

  @override
  bool shouldRepaint(_TapePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.rtl != rtl;
}
