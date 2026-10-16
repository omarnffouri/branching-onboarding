import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The drawn fallback when a measurement has no configured photo.
class WaistTorso extends StatelessWidget {
  const WaistTorso({required this.waistY, super.key});

  final double waistY;

  /// Shared with the tape so it wraps the illustrated waist accurately.
  static const waistHalfWidth = 0.25;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _TorsoPainter(waistY: waistY));
}

/// A smooth, matte "clay" torso, front view, in the blush palette.
///
/// Volume comes from layered gradients rather than an image: the body is
/// darker at its edges and lighter in the middle (a cylinder in soft light),
/// with shadow under the ribs, a highlight across the belly and a soft navel.
class _TorsoPainter extends CustomPainter {
  const _TorsoPainter({required this.waistY});

  /// The waist line on screen; the narrowest point of the silhouette.
  final double waistY;

  static const _skinLight = Color(0xFFF8D9DF);
  static const _skin = Color(0xFFEDB9C4);
  static const _skinShadow = Color(0xFFD796A6);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Backdrop: a soft blush studio sweep.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, (waistY / h) * 2 - 1),
          radius: 1.1,
          colors: const [Color(0xFFFFF3F5), Color(0xFFF6DCE3)],
        ).createShader(Offset.zero & size),
    );

    // Half-widths along the body, top to bottom: ribs, waist, hips.
    final top = waistY - h * 0.34;
    final bottom = waistY + h * 0.36;
    double halfWidth(double y) {
      final t = (y - waistY) / (y < waistY ? waistY - top : bottom - waistY);
      final edge = y < waistY ? 0.33 : 0.37;
      // Smooth curve: narrowest at the waist, flaring out above and below.
      final eased = t.abs() < 1 ? (1 - math.cos(t.abs() * math.pi)) / 2 : 1.0;
      return w *
          (WaistTorso.waistHalfWidth +
              (edge - WaistTorso.waistHalfWidth) * eased);
    }

    final body = Path()..moveTo(cx - halfWidth(top), top);
    for (var y = top; y <= bottom; y += 4) {
      body.lineTo(cx - halfWidth(y), y);
    }
    for (var y = bottom; y >= top; y -= 4) {
      body.lineTo(cx + halfWidth(y), y);
    }
    body.close();

    final bounds = Rect.fromLTRB(0, top, w, bottom);
    final navel = Offset(cx, waistY + h * 0.075);
    canvas
      // A soft contact shadow so the figure sits off the backdrop.
      ..drawShadow(body, const Color(0xFF8A3650), 18, false)
      // The cylinder: darker at the sides, light down the middle.
      ..drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
            colors: [_skinShadow, _skin, _skinLight, _skin, _skinShadow],
            stops: [0.12, 0.3, 0.5, 0.7, 0.88],
          ).createShader(bounds),
      )
      ..save()
      ..clipPath(body)
      // Shadow under the ribcage and a highlight across the belly.
      ..drawOval(
        Rect.fromCenter(
          center: Offset(cx, top + (waistY - top) * 0.1),
          width: w * 0.7,
          height: h * 0.12,
        ),
        Paint()
          ..color = _skinShadow.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(cx, waistY + h * 0.06),
          width: w * 0.32,
          height: h * 0.2,
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      )
      // A faint centre line, like a sculpted midline.
      ..drawLine(
        Offset(cx, top + h * 0.06),
        Offset(cx, waistY + h * 0.03),
        Paint()
          ..color = _skinShadow.withValues(alpha: 0.25)
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      )
      // The navel, a soft dimple just below the waist.
      ..drawOval(
        Rect.fromCenter(center: navel, width: 11, height: 16),
        Paint()
          ..shader = RadialGradient(
            colors: [
              _skinShadow.withValues(alpha: 0.95),
              _skinShadow.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: navel, radius: 10)),
      )
      ..restore()
      // Fade the bottom of the figure into the backdrop.
      ..drawRect(
        Rect.fromLTRB(0, bottom - h * 0.18, w, bottom + 2),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00F6DCE3), Color(0xFFF6DCE3)],
          ).createShader(Rect.fromLTRB(0, bottom - h * 0.18, w, bottom + 2)),
      );
  }

  @override
  bool shouldRepaint(_TorsoPainter oldDelegate) => oldDelegate.waistY != waistY;
}
