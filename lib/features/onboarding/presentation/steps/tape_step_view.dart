import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_hero.dart';

/// A number answered by measuring: a tape wraps around her waist in the
/// photo, and she drags it to the right mark.
///
/// The tape is drawn as if wrapped around a cylinder, so marks shrink and
/// fade as they turn away at the sides. It glides with her finger, snaps
/// to whole numbers when she lets go, and ticks with a haptic on each one.
class TapeStepView extends ConsumerStatefulWidget {
  const TapeStepView({required this.step, super.key});

  final NumberStep step;

  @override
  ConsumerState<TapeStepView> createState() => _TapeStepViewState();
}

class _TapeStepViewState extends ConsumerState<TapeStepView>
    with SingleTickerProviderStateMixin {
  /// Pixels of tape per unit (per cm).
  static const _spacing = 18.0;

  late double _value = switch (ref
      .read(onboardingControllerProvider)
      .answers[widget.step.id]) {
    NumberAnswer(:final value) => value.toDouble(),
    _ => widget.step.initial.toDouble(),
  };
  late int _shown = _value.round();
  late final AnimationController _snap;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController.unbounded(vsync: this)
      ..addListener(() => _setValue(_snap.value));
  }

  void _setValue(double value) {
    final clamped = value.clamp(
      widget.step.min.toDouble(),
      widget.step.max.toDouble(),
    );
    setState(() => _value = clamped);
    final rounded = clamped.round();
    if (rounded != _shown) {
      _shown = rounded;
      HapticFeedback.selectionClick().ignore();
    }
  }

  void _onDrag(DragUpdateDetails details) {
    _snap.stop();
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    // Dragging the tape to the left reveals higher numbers, like pulling it.
    _setValue(_value - direction * details.delta.dx / _spacing);
  }

  void _onDragEnd(DragEndDetails details) {
    final target = _value.round().toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _setValue(target);
    } else {
      _snap
        ..value = _value
        ..animateTo(
          target,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        ).ignore();
    }
    _save();
  }

  void _step(int delta) {
    _setValue((_value.round() + delta).toDouble());
    _save();
  }

  void _save() => ref
      .read(onboardingControllerProvider.notifier)
      .answer(widget.step.id, NumberAnswer(_value.round()));

  void _continue() {
    _save();
    ref
        .read(onboardingControllerProvider.notifier)
        .continueFrom(widget.step.id);
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final step = widget.step;
    final unit = step.unit.resolve(language);
    final size = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Where her waist sits on screen: the photo fills the height, so a
    // fraction of the photo is the same fraction of the screen.
    final waistY = size.height * step.measureAt;
    // Where the number begins: the body has fully faded out by here, so
    // the fade runs straight into the answer with no empty band.
    final answerTop =
        (size.height - MediaQuery.paddingOf(context).bottom - 200) /
        size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        slider: true,
        label: formatter.fill(step.title, answers),
        value: '$_shown $unit',
        increasedValue: '${_shown + 1} $unit',
        decreasedValue: '${_shown - 1} $unit',
        onIncrease: () => _step(1),
        onDecrease: () => _step(-1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDrag,
          onHorizontalDragEnd: _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A photo if the config names one, otherwise our own
              // sculpted torso, drawn in the palette.
              if (step.image case final image?)
                Image(
                  image: StepHero.providerFor(image),
                  fit: BoxFit.cover,
                  alignment: Alignment(step.imageFocus.x, step.imageFocus.y),
                )
              else
                CustomPaint(painter: _TorsoPainter(waistY: waistY)),
              // Light veils keep text readable on the photo. The lower one
              // starts just under the measured line and fades the body out
              // completely, so only the waist stays in focus.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                      0,
                      0.3,
                      0.4,
                      step.measureAt + 0.07,
                      step.measureAt + 0.16,
                      answerTop,
                      1,
                    ],
                    colors: const [
                      Color(0xF2FFF7F7),
                      Color(0xB3FFF7F7),
                      Color(0x00FFF7F7),
                      Color(0x00FFF7F7),
                      Color(0xD4FFF7F7),
                      AppColors.background,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
              Entrance(
                index: 2,
                child: CustomPaint(
                  painter: _TapePainter(
                    value: _value,
                    min: step.min,
                    max: step.max,
                    spacing: _spacing,
                    centerY: waistY,
                    // Wraps the torso at the waist when we draw it.
                    radius: switch ((step.image, step.measureWidth)) {
                      (null, _) =>
                        size.width * _TorsoPainter.waistHalfWidth + 6,
                      (_, final width?) => size.width * width / 2,
                      _ => size.width * 0.52,
                    },
                    rtl: rtl,
                  ),
                ),
              ),
              // The answer sits at the bottom, where the body fades out.
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                left: AppSpacing.page,
                right: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Entrance(
                      index: 3,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_shown',
                                style: text.displaySmall!.copyWith(
                                  fontFamily: 'Poppins',
                                  fontSize: 56,
                                  color: AppColors.primary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(unit, style: text.titleLarge),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swipe_rounded,
                                size: 18,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(l10n.tapeHint, style: text.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.continueButton,
                      onPressed: _continue,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    FlowHeader.extentOf(context) + 16,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        index: 0,
                        child: Text(
                          formatter.fill(step.title, answers),
                          style: text.headlineMedium,
                        ),
                      ),
                      if (step.subtitle case final subtitle?) ...[
                        const SizedBox(height: 10),
                        Entrance(
                          index: 1,
                          child: Text(
                            subtitle.resolve(language),
                            style: text.bodyLarge!.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

/// A smooth, matte "clay" torso, front view, in the blush palette.
///
/// Volume comes from layered gradients rather than an image: the body is
/// darker at its edges and lighter in the middle (a cylinder in soft light),
/// with shadow under the ribs, a highlight across the belly and a soft navel.
class _TorsoPainter extends CustomPainter {
  const _TorsoPainter({required this.waistY});

  /// The waist line on screen; the narrowest point of the silhouette.
  final double waistY;

  /// Half the waist width as a fraction of the screen width.
  static const waistHalfWidth = 0.25;

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
      return w * (waistHalfWidth + (edge - waistHalfWidth) * eased);
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
