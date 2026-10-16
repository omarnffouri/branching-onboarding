import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/config_icons.dart';

typedef FlowPoint = ({String icon, String title, String text});

/// An info screen's message as a few short steps joined by a line, with a
/// drop of colour flowing down it: lymphatic drainage, explained by motion
/// instead of a paragraph.
///
/// Steps arrive one after another with the page; the drop loops slowly,
/// one segment at a time, and stays put under reduced motion.
class FlowPoints extends StatefulWidget {
  const FlowPoints({required this.points, this.firstIndex = 0, super.key});

  final List<FlowPoint> points;

  /// Entrance index of the first step, to continue the page's stagger.
  final int firstIndex;

  @override
  State<FlowPoints> createState() => _FlowPointsState();
}

class _FlowPointsState extends State<FlowPoints>
    with SingleTickerProviderStateMixin {
  late final _flow = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1600 * widget.points.length),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _flow.stop();
    } else if (!_flow.isAnimating) {
      unawaited(_flow.repeat());
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.points.length - 1;
    return Column(
      children: [
        for (final (i, point) in widget.points.indexed)
          Entrance(
            index: widget.firstIndex + i,
            child: _PointRow(
              point: point,
              isLast: i == widget.points.length - 1,
              // Each segment carries the drop for its share of the loop.
              drop: i < segments
                  ? _flow.drive(
                      CurveTween(
                        curve: Interval(
                          i / segments,
                          (i + 1) / segments,
                          curve: Curves.easeInOut,
                        ),
                      ),
                    )
                  : null,
              still: MediaQuery.disableAnimationsOf(context),
            ),
          ),
      ],
    );
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.point,
    required this.isLast,
    required this.drop,
    required this.still,
  });

  final FlowPoint point;
  final bool isLast;
  final Animation<double>? drop;
  final bool still;

  static const _iconSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _iconSize,
            child: Column(
              children: [
                Container(
                  width: _iconSize,
                  height: _iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.blush, width: 3),
                    boxShadow: AppShadows.card,
                  ),
                  child: Icon(
                    iconFor(point.icon),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: _Connector(drop: drop, still: still),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(point.title, style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    point.text,
                    style: text.bodyLarge!.copyWith(fontSize: 15.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The line between two steps, and the drop travelling down it. Painted
/// rather than laid out, so it simply fills whatever height the step has.
class _Connector extends StatelessWidget {
  const _Connector({required this.drop, required this.still});

  final Animation<double>? drop;
  final bool still;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ConnectorPainter(still ? null : drop),
    child: const SizedBox(width: 12),
  );
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.drop) : super(repaint: drop);

  final Animation<double>? drop;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final line = Rect.fromLTRB(x - 1, 4, x + 1, size.height - 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(line, const Radius.circular(1)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primarySoft, AppColors.blush],
        ).createShader(line),
    );

    final t = drop?.value ?? 0;
    if (drop == null || t <= 0 || t >= 1) return;
    // Fade in at the top and out at the bottom of the segment.
    final opacity = t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
    final center = Offset(x, 8 + t * (size.height - 16));
    canvas
      ..drawCircle(
        center,
        8,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawCircle(
        center,
        5,
        Paint()..color = AppColors.primary.withValues(alpha: opacity),
      );
  }

  @override
  bool shouldRepaint(_ConnectorPainter oldDelegate) => oldDelegate.drop != drop;
}
