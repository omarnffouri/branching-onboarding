import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

enum BodySide { front, back }

extension on BodyRegion {
  /// Arms and legs read from both sides; the rest belong to one.
  bool visibleOn(BodySide side) => switch (this) {
    BodyRegion.belly => side == BodySide.front,
    BodyRegion.back || BodyRegion.glutes => side == BodySide.back,
    BodyRegion.arms || BodyRegion.legs => true,
  };
}

/// Focus areas picked on a figure she can turn around, with the same
/// options as chips underneath. The chips are the accessible, precise way
/// in; the figure is the quick, personal one. Both stay in sync.
class BodyMap extends StatefulWidget {
  const BodyMap({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.labelOf,
    required this.height,
    super.key,
  });

  /// Every option has a region; the config validator guarantees it.
  final List<ChoiceOption> options;
  final Set<String> selected;
  final ValueChanged<ChoiceOption> onToggle;
  final String Function(ChoiceOption option) labelOf;
  final double height;

  @override
  State<BodyMap> createState() => _BodyMapState();
}

class _BodyMapState extends State<BodyMap> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final Map<BodyRegion, AnimationController> _fills;
  BodySide _side = BodySide.front;
  Set<BodyRegion> get _selectedRegions => {
    for (final option in widget.options)
      if (widget.selected.contains(option.id)) ?option.region,
  };

  Duration _duration(Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this);
    final selected = _selectedRegions;
    _fills = {
      for (final region in BodyRegion.values)
        region: AnimationController(
          vsync: this,
          value: selected.contains(region) ? 1 : 0,
        ),
    };
  }

  @override
  void didUpdateWidget(BodyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedRegions;
    for (final MapEntry(key: region, value: fill) in _fills.entries) {
      fill
          .animateTo(
            selected.contains(region) ? 1 : 0,
            duration: _duration(AppMotion.medium),
            curve: AppMotion.emphasized,
          )
          .ignore();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    for (final fill in _fills.values) {
      fill.dispose();
    }
    super.dispose();
  }

  void _turnTo(BodySide side) {
    if (_side == side) return;
    setState(() => _side = side);
    _flip
        .animateTo(
          side == BodySide.back ? 1 : 0,
          duration: _duration(AppMotion.slow),
          curve: Curves.easeInOutCubic,
        )
        .ignore();
  }

  /// Picking an area she can't see turns the figure so it lands in view.
  void _toggle(ChoiceOption option) {
    final region = option.region!;
    if (!widget.selected.contains(option.id) && !region.visibleOn(_side)) {
      _turnTo(_side == BodySide.front ? BodySide.back : BodySide.front);
    }
    widget.onToggle(option);
  }

  void _onFigureTap(TapUpDetails details, Size size) {
    if (_flip.isAnimating) return;
    final scale = math.min(
      size.width / _Figure.size.width,
      size.height / _Figure.size.height,
    );
    final origin = Offset(
      (size.width - _Figure.size.width * scale) / 2,
      (size.height - _Figure.size.height * scale) / 2,
    );
    final point = (details.localPosition - origin) / scale;
    final region = _Figure.of(_side).regionAt(point);
    if (region == null) return;
    for (final option in widget.options) {
      if (option.region == region) {
        HapticFeedback.selectionClick().ignore();
        _toggle(option);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offered = {for (final option in widget.options) ?option.region};
    return Column(
      children: [
        _SideToggle(side: _side, l10n: l10n, onChanged: _turnTo),
        const SizedBox(height: AppSpacing.md),
        ExcludeSemantics(
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                key: const ValueKey('body-figure'),
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _onFigureTap(details, constraints.biggest),
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (context, child) {
                    final turn = _flip.value;
                    final showsBack = turn > 0.5;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(turn * math.pi);
                    // Past halfway the far side faces her; unmirror it.
                    if (showsBack) {
                      transform.multiply(Matrix4.diagonal3Values(-1, 1, 1));
                    }
                    return Transform(
                      alignment: Alignment.center,
                      transform: transform,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _BodyPainter(
                          figure: _Figure.of(
                            showsBack ? BodySide.back : BodySide.front,
                          ),
                          offered: offered,
                          fills: _fills,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in widget.options)
              _AreaChip(
                key: ValueKey('body-chip:${option.id}'),
                label: widget.labelOf(option),
                selected: widget.selected.contains(option.id),
                onTap: () => _toggle(option),
              ),
          ],
        ),
      ],
    );
  }
}

class _SideToggle extends StatelessWidget {
  const _SideToggle({
    required this.side,
    required this.l10n,
    required this.onChanged,
  });

  final BodySide side;
  final AppLocalizations l10n;
  final ValueChanged<BodySide> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget segment(BodySide value, String label) {
      final selected = side == value;
      return Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Pressable(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: selected ? AppShadows.card : null,
            ),
            child: Text(
              label,
              style: text.labelLarge!.copyWith(
                color: selected ? AppColors.primaryDeep : AppColors.inkMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(BodySide.front, l10n.bodyFront),
          segment(BodySide.back, l10n.bodyBack),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: selected,
    child: Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standard,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blush : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                key: ValueKey(selected),
                size: 18,
                color: selected ? AppColors.primary : AppColors.primarySoft,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: selected ? AppColors.primaryDeep : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A tappable piece of a region: the shape where it overlaps the band.
typedef _Piece = (Path shape, Rect band);

/// The figure in a 200 × 420 design space, built once per side.
final class _Figure {
  _Figure._(this.side) {
    Path mirrored(Path path) => path
        .transform(Matrix4.diagonal3Values(-1, 1, 1).storage)
        .shift(Offset(size.width, 0));

    final leftArm = _limb(const [
      (60, 92, 10),
      (52, 118, 10),
      (46, 150, 8.5),
      (43, 166, 7),
      (39, 195, 7),
      (35, 228, 5.5),
    ]);
    final leftLeg = _limb(const [
      (80, 248, 21),
      (78, 290, 19),
      (77, 322, 14),
      (77, 338, 11.5),
      (76, 365, 11),
      (76, 392, 7.5),
      (77, 402, 6),
    ]);
    arms = Path()
      ..addPath(leftArm, Offset.zero)
      ..addPath(mirrored(leftArm), Offset.zero);
    legs = Path()
      ..addPath(leftLeg, Offset.zero)
      ..addPath(mirrored(leftLeg), Offset.zero);
    torso = _limb(const [
      (100, 80, 30),
      (100, 90, 47),
      (100, 110, 45),
      (100, 140, 38),
      (100, 172, 31),
      (100, 200, 35),
      (100, 232, 41),
      (100, 262, 40),
      (100, 276, 28),
    ]);
    extremities = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(33, 240), width: 11, height: 17),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(167, 240), width: 11, height: 17),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(74, 407), width: 19, height: 9),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(126, 407), width: 19, height: 9),
      )
      ..addRRect(
        RRect.fromLTRBR(91, 56, 109, 86, const Radius.circular(8)),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(100, 38), width: 40, height: 50),
      );

    const armBand = Rect.fromLTRB(0, 98, 200, 236);
    regions = switch (side) {
      BodySide.front => {
        BodyRegion.belly: [(torso, const Rect.fromLTRB(0, 142, 200, 232))],
        BodyRegion.legs: [(legs, const Rect.fromLTRB(0, 270, 200, 404))],
        BodyRegion.arms: [(arms, armBand)],
      },
      BodySide.back => {
        BodyRegion.back: [(torso, const Rect.fromLTRB(0, 86, 200, 206))],
        BodyRegion.glutes: [
          (torso, const Rect.fromLTRB(0, 210, 200, 284)),
          (legs, const Rect.fromLTRB(0, 210, 200, 284)),
        ],
        BodyRegion.legs: [(legs, const Rect.fromLTRB(0, 286, 200, 404))],
        BodyRegion.arms: [(arms, armBand)],
      },
    };
  }

  factory _Figure.of(BodySide side) =>
      _cache.putIfAbsent(side, () => _Figure._(side));

  static const size = Size(200, 420);
  static final _cache = <BodySide, _Figure>{};

  final BodySide side;
  late final Path arms;
  late final Path legs;
  late final Path torso;

  /// Head, neck, hands and feet: part of her, never a focus area.
  late final Path extremities;

  /// Ordered for hit testing: the torso areas win over a limb they touch.
  late final Map<BodyRegion, List<_Piece>> regions;

  BodyRegion? regionAt(Offset point) {
    for (final MapEntry(key: region, value: pieces) in regions.entries) {
      for (final (shape, band) in pieces) {
        if (band.contains(point) && shape.contains(point)) return region;
      }
    }
    return null;
  }

  /// A tapered, rounded limb along a spine of (x, y, half-width) points.
  static Path _limb(List<(double, double, double)> spine) {
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < spine.length; i++) {
      final (x, y, r) = spine[i];
      final (px, py, _) = spine[math.max(0, i - 1)];
      final (nx, ny, _) = spine[math.min(spine.length - 1, i + 1)];
      final direction = Offset(nx - px, ny - py);
      final normal = Offset(-direction.dy, direction.dx) / direction.distance;
      left.add(Offset(x, y) + normal * r);
      right.add(Offset(x, y) - normal * r);
    }
    Offset cap(int at, int toward) {
      final (x, y, r) = spine[at];
      final (tx, ty, _) = spine[toward];
      final away = Offset(x - tx, y - ty);
      return Offset(x, y) + away / away.distance * r * 0.9;
    }

    final outline = [
      cap(0, 1),
      ...left,
      cap(spine.length - 1, spine.length - 2),
      ...right.reversed,
    ];
    // Midpoint quadratics through every point: smooth, no corners.
    final n = outline.length;
    Offset mid(int i) => (outline[i % n] + outline[(i + 1) % n]) / 2;
    final path = Path()..moveTo(mid(0).dx, mid(0).dy);
    for (var i = 1; i <= n; i++) {
      final control = outline[i % n];
      final end = mid(i);
      path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    }
    return path..close();
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.figure,
    required this.offered,
    required this.fills,
  }) : super(repaint: Listenable.merge(fills.values.toList()));

  final _Figure figure;
  final Set<BodyRegion> offered;
  final Map<BodyRegion, AnimationController> fills;

  static const _skinLight = Color(0xFFF8D9DF);
  static const _skin = Color(0xFFEDB9C4);
  static const _skinShadow = Color(0xFFD796A6);
  static const _hair = Color(0xFF5E2B3A);

  @override
  void paint(Canvas canvas, Size size) {
    const design = _Figure.size;
    final scale = math.min(
      size.width / design.width,
      size.height / design.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - design.width * scale) / 2,
        (size.height - design.height * scale) / 2,
      )
      ..scale(scale);

    final bounds = Offset.zero & design;
    final clay = Paint()
      ..shader = const LinearGradient(
        colors: [_skinShadow, _skin, _skinLight, _skin, _skinShadow],
        stops: [0.18, 0.34, 0.5, 0.66, 0.82],
      ).createShader(bounds);

    // Ground shadow, then limbs behind the torso so shoulders and hips blend.
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 412), width: 120, height: 14),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(figure.arms, clay)
      ..drawPath(figure.legs, clay)
      ..drawPath(figure.extremities, clay)
      ..drawPath(figure.torso, clay);

    _paintHair(canvas);
    if (figure.side == BodySide.back) {
      canvas.drawLine(
        const Offset(100, 92),
        const Offset(100, 205),
        Paint()
          ..color = _skinShadow.withValues(alpha: 0.45)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    for (final MapEntry(key: region, value: pieces) in figure.regions.entries) {
      if (!offered.contains(region)) continue;
      _paintRegion(canvas, pieces, fills[region]!.value);
    }
    canvas.restore();
  }

  void _paintHair(Canvas canvas) {
    final hair = Paint()..color = _hair;
    canvas.drawCircle(const Offset(100, 12), 9, hair);
    if (figure.side == BodySide.back) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 37), width: 43, height: 53),
        hair,
      );
    } else {
      canvas
        ..save()
        ..clipRect(const Rect.fromLTRB(0, 0, 200, 27))
        ..drawOval(
          Rect.fromCenter(center: const Offset(100, 36), width: 43, height: 52),
          hair,
        )
        ..restore();
    }
  }

  void _paintRegion(Canvas canvas, List<_Piece> pieces, double t) {
    for (final (shape, band) in pieces) {
      canvas
        ..save()
        ..clipRect(band);
      if (t > 0) {
        canvas.drawPath(
          shape,
          Paint()
            ..color = AppColors.primary.withValues(alpha: 0.35 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
      canvas
        ..drawPath(
          shape,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.82),
                  t,
                )!,
                Color.lerp(
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryDeep.withValues(alpha: 0.82),
                  t,
                )!,
              ],
            ).createShader(band),
        )
        ..restore();
      // Hairline seams so each area reads as its own tappable piece.
      final seam = Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      canvas
        ..save()
        ..clipPath(shape);
      for (final y in [band.top, band.bottom]) {
        canvas.drawLine(Offset(0, y), Offset(_Figure.size.width, y), seam);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.figure != figure || oldDelegate.offered != offered;
}
