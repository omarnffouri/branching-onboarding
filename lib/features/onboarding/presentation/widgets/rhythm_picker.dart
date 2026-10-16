import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';

/// A tactile number with one continuous ribbon that opens as her pace grows.
class RhythmPicker extends StatefulWidget {
  const RhythmPicker({
    required this.count,
    required this.min,
    required this.max,
    required this.extent,
    required this.onChanged,
    super.key,
  });

  final int count;
  final int min;
  final int max;
  final double extent;
  final ValueChanged<int> onChanged;

  @override
  State<RhythmPicker> createState() => _RhythmPickerState();
}

class _RhythmPickerState extends State<RhythmPicker> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 600);
    return Column(
      children: [
        Semantics(
          label: l10n.weekEyebrow,
          value: l10n.rhythmValue(widget.count),
          increasedValue: widget.count < widget.max
              ? l10n.rhythmValue(widget.count + 1)
              : null,
          decreasedValue: widget.count > widget.min
              ? l10n.rhythmValue(widget.count - 1)
              : null,
          hint: l10n.rhythmSwipe,
          slider: true,
          onIncrease: widget.count < widget.max
              ? () => widget.onChanged(widget.count + 1)
              : null,
          onDecrease: widget.count > widget.min
              ? () => widget.onChanged(widget.count - 1)
              : null,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('rhythm-picker'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragDown: (details) =>
                _drag = details.globalPosition.dx,
            onHorizontalDragUpdate: (details) {
              // Include touch slop so short swipes work as reliably as drags.
              final distance = details.globalPosition.dx - _drag;
              if (distance.abs() < 52) return;
              final direction = Directionality.of(context) == TextDirection.rtl
                  ? -1
                  : 1;
              widget.onChanged(
                widget.count + (distance > 0 ? 1 : -1) * direction,
              );
              _drag = details.globalPosition.dx;
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: widget.count.toDouble()),
              duration: duration,
              curve: AppMotion.emphasized,
              builder: (context, pace, child) => CustomPaint(
                painter: _RhythmRibbon(pace),
                child: child,
              ),
              child: SizedBox.square(
                dimension: widget.extent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: reduceMotion ? Duration.zero : AppMotion.slow,
                      switchInCurve: AppMotion.emphasized,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.16),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${widget.count}',
                        key: ValueKey('rhythm-count:${widget.count}'),
                        style: text.displaySmall!.copyWith(
                          fontFamily: 'Poppins',
                          fontSize: widget.extent * 0.34,
                          height: 1.05,
                          letterSpacing: -5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDeep,
                        ),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.rhythmSessions,
                      style: text.bodySmall!.copyWith(
                        color: AppColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountButton(
              label: l10n.rhythmLess,
              icon: Icons.remove_rounded,
              onTap: widget.count > widget.min
                  ? () => widget.onChanged(widget.count - 1)
                  : null,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.rhythmSwipe,
                  textAlign: TextAlign.center,
                  style: text.bodySmall!.copyWith(fontSize: 11.5),
                ),
              ),
            ),
            _CountButton(
              label: l10n.rhythmMore,
              icon: Icons.add_rounded,
              onTap: () => widget.onChanged(widget.count + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    enabled: onTap != null,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      haptic: PressHaptic.none,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primarySoft.withValues(
                  alpha: onTap == null ? 0.3 : 0.8,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onTap == null ? AppColors.primarySoft : AppColors.primary,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RhythmRibbon extends CustomPainter {
  const _RhythmRibbon(this.pace);

  final double pace;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.39;
    final fullness = (pace - 2) / 3;
    final phase = -0.8 + fullness * 0.5;
    final path = Path();
    for (var i = 0; i <= 240; i++) {
      final angle = i / 240 * math.pi * 2;
      final wave =
          1 +
          (0.075 + fullness * 0.025) * math.sin(angle * 3 + phase) +
          0.035 * math.cos(angle * 2 - phase);
      final point =
          center +
          Offset(
            math.cos(angle) * radius * wave * (1 + fullness * 0.025),
            math.sin(angle) * radius * wave * 0.96,
          );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    final bounds = Rect.fromCircle(center: center, radius: radius * 1.2);
    canvas
      ..drawCircle(
        center,
        radius * 0.92,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.blush.withValues(alpha: 0.55),
              AppColors.background.withValues(alpha: 0),
            ],
          ).createShader(bounds),
      )
      ..drawPath(
        path.shift(const Offset(0, 8)),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 23 + fullness * 4
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            transform: GradientRotation(phase),
            colors: const [
              Color(0xFFEEC5CE),
              Color(0xFFC5748D),
              Color(0xFFF7DBE2),
              Color(0xFFDFA4B5),
              Color(0xFFAD526E),
              Color(0xFFEEC5CE),
            ],
            stops: const [0, 0.24, 0.43, 0.65, 0.84, 1],
          ).createShader(bounds),
      )
      ..drawPath(
        path.shift(const Offset(-1, -2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withValues(alpha: 0.28),
      );
  }

  @override
  bool shouldRepaint(_RhythmRibbon oldDelegate) => oldDelegate.pace != pace;
}
