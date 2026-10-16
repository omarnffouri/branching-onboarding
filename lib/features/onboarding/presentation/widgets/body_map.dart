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
///
/// One continuous, curved silhouette (shoulders, a real waist, hips,
/// tapered legs) drawn as a smooth spline, with the arms slightly apart.
/// Areas are bands of that same silhouette, so a highlight always follows
/// her outline instead of a box.
final class _Figure {
  _Figure._(this.side) {
    // Left half of the body, outside edge top to bottom, then up the inner
    // leg. The right half is its mirror image.
    const half = [
      Offset(92, 60), // neck
      Offset(83, 70),
      Offset(67, 79), // shoulder slope
      Offset(57, 89),
      Offset(55, 101), // shoulder
      Offset(62, 118), // under the arm
      Offset(66, 140), // ribs
      Offset(71, 163),
      Offset(73, 178), // waist
      Offset(69, 196),
      Offset(61, 214), // hip
      Offset(58, 232),
      Offset(61, 258), // outer thigh
      Offset(66, 290),
      Offset(71, 322), // knee
      Offset(70, 346), // calf
      Offset(73, 370),
      Offset(78, 392), // ankle
      Offset(74, 404),
      Offset(84, 411), // foot
      Offset(93, 409),
      Offset(90, 394), // inner ankle
      Offset(89, 372),
      Offset(90, 346), // inner calf
      Offset(92, 322), // inner knee
      Offset(94, 292),
      Offset(97, 266), // inner thigh
      Offset(100, 258),
    ];
    Offset mirror(Offset point) => Offset(size.width - point.dx, point.dy);
    body = _smooth([
      ...half,
      for (final point in half.reversed.skip(1)) mirror(point),
    ]);

    final leftArm = _limb(const [
      (60, 94, 9.5),
      (53, 120, 9),
      (48, 148, 7.5),
      (45, 168, 6.5),
      (41, 198, 6),
      (38, 226, 4.8),
    ]);
    arms = Path()
      ..addPath(leftArm, Offset.zero)
      ..addPath(
        leftArm
            .transform(Matrix4.diagonal3Values(-1, 1, 1).storage)
            .shift(Offset(size.width, 0)),
        Offset.zero,
      );

    extremities = Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(36, 238), width: 11, height: 18),
      )
      ..addOval(
        Rect.fromCenter(center: const Offset(164, 238), width: 11, height: 18),
      )
      ..addRRect(RRect.fromLTRBR(92, 48, 108, 68, const Radius.circular(7)))
      ..addOval(
        Rect.fromCenter(center: const Offset(100, 32), width: 36, height: 44),
      );

    const armBand = Rect.fromLTRB(0, 100, 200, 232);
    regions = switch (side) {
      BodySide.front => {
        BodyRegion.belly: [(body, const Rect.fromLTRB(0, 138, 200, 236))],
        BodyRegion.legs: [(body, const Rect.fromLTRB(0, 262, 200, 404))],
        BodyRegion.arms: [(arms, armBand)],
      },
      BodySide.back => {
        BodyRegion.back: [(body, const Rect.fromLTRB(0, 82, 200, 204))],
        BodyRegion.glutes: [(body, const Rect.fromLTRB(0, 204, 200, 266))],
        BodyRegion.legs: [(body, const Rect.fromLTRB(0, 266, 200, 404))],
        BodyRegion.arms: [(arms, armBand)],
      },
    };
  }

  factory _Figure.of(BodySide side) =>
      _cache.putIfAbsent(side, () => _Figure._(side));

  static const size = Size(200, 420);
  static final _cache = <BodySide, _Figure>{};

  final BodySide side;

  /// Torso and legs as one silhouette.
  late final Path body;
  late final Path arms;

  /// Head, neck and hands: part of her, never a focus area.
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

  /// A closed Catmull-Rom spline through [points]: every point is on the
  /// curve and there are no corners.
  static Path _smooth(List<Offset> points) {
    final n = points.length;
    Offset at(int i) => points[(i % n + n) % n];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < n; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final p2 = at(i + 1);
      final p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
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

    return _smooth([
      cap(0, 1),
      ...left,
      cap(spine.length - 1, spine.length - 2),
      ...right.reversed,
    ]);
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

  static const _skinLight = Color(0xFFFBE4E8);
  static const _skin = Color(0xFFF0C3CC);
  static const _skinShadow = Color(0xFFDDA2B0);
  static const _contour = Color(0xFFC98A9A);
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
    // A soft cylinder: darker at her sides, lit down the middle.
    final clay = Paint()
      ..shader = const LinearGradient(
        colors: [_skinShadow, _skin, _skinLight, _skin, _skinShadow],
        stops: [0.24, 0.38, 0.5, 0.62, 0.76],
      ).createShader(bounds);
    final limbClay = Paint()
      ..shader = const LinearGradient(
        colors: [_skinShadow, _skin, _skinLight, _skin, _skinShadow],
        stops: [0.1, 0.2, 0.5, 0.8, 0.9],
      ).createShader(bounds);
    final contour = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = _contour.withValues(alpha: 0.45);

    // Ground shadow, then arms behind the body so the shoulders blend.
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 414), width: 110, height: 12),
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..drawPath(figure.arms, limbClay)
      ..drawPath(figure.arms, contour)
      ..drawPath(figure.extremities, clay)
      ..drawPath(figure.body, clay);

    _paintShading(canvas);
    for (final MapEntry(key: region, value: pieces) in figure.regions.entries) {
      if (!offered.contains(region)) continue;
      _paintRegion(canvas, pieces, fills[region]!.value);
    }
    canvas.drawPath(figure.body, contour);
    _paintDetails(canvas);
    _paintHair(canvas);
    canvas.restore();
  }

  /// Soft volume inside the silhouette: a shadow under the ribs, light on
  /// the belly and thighs.
  void _paintShading(Canvas canvas) {
    canvas
      ..save()
      ..clipPath(figure.body)
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 132), width: 70, height: 26),
        Paint()
          ..color = _skinShadow.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 196), width: 34, height: 60),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 252), width: 18, height: 26),
        Paint()
          ..color = _skinShadow.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore();
  }

  /// A few quiet lines that make the figure read as a body.
  void _paintDetails(Canvas canvas) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.3
      ..color = _contour.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);
    if (figure.side == BodySide.front) {
      // Collarbones and the navel.
      canvas
        ..drawPath(
          Path()
            ..moveTo(94, 74)
            ..quadraticBezierTo(82, 73, 70, 80)
            ..moveTo(106, 74)
            ..quadraticBezierTo(118, 73, 130, 80),
          line,
        )
        ..drawOval(
          Rect.fromCenter(
            center: const Offset(100, 190),
            width: 3.4,
            height: 5,
          ),
          Paint()..color = _contour.withValues(alpha: 0.7),
        );
    } else {
      // Spine and shoulder blades.
      canvas
        ..drawLine(const Offset(100, 74), const Offset(100, 202), line)
        ..drawPath(
          Path()
            ..moveTo(86, 98)
            ..quadraticBezierTo(76, 112, 84, 128)
            ..moveTo(114, 98)
            ..quadraticBezierTo(124, 112, 116, 128),
          line,
        )
        ..drawPath(
          Path()
            ..moveTo(100, 226)
            ..quadraticBezierTo(100, 244, 100, 254),
          line,
        );
    }
  }

  void _paintHair(Canvas canvas) {
    final hair = Paint()..color = _hair;
    canvas.drawCircle(const Offset(100, 7), 8.5, hair);
    if (figure.side == BodySide.back) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 31), width: 39, height: 47),
        hair,
      );
    } else {
      canvas
        ..save()
        ..clipRect(const Rect.fromLTRB(0, 0, 200, 22))
        ..drawOval(
          Rect.fromCenter(center: const Offset(100, 31), width: 39, height: 47),
          hair,
        )
        ..restore();
    }
  }

  /// A highlight that follows the silhouette and fades out at the top and
  /// bottom of its area, so there is never a hard edge or a seam.
  void _paintRegion(Canvas canvas, List<_Piece> pieces, double t) {
    for (final (shape, band) in pieces) {
      // Offered but not picked: a faint hint that the area is tappable.
      final strength = 0.1 + 0.7 * t;
      canvas
        ..save()
        ..clipPath(shape)
        ..drawRect(
          band,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0),
                AppColors.primary.withValues(alpha: strength),
                AppColors.primaryDeep.withValues(alpha: strength),
                AppColors.primaryDeep.withValues(alpha: 0),
              ],
              stops: const [0, 0.22, 0.78, 1],
            ).createShader(band),
        );
      if (t > 0) {
        // A soft inner glow, brightest in the middle of the area.
        canvas.drawOval(
          Rect.fromCenter(
            center: band.center,
            width: band.width * 0.3,
            height: band.height * 0.6,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.18 * t)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BodyPainter oldDelegate) =>
      oldDelegate.figure != figure || oldDelegate.offered != offered;
}
