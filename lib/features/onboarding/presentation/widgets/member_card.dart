import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/flow_background.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';

/// Her Traininpink member card.
///
/// It opens the flow, writing her name as she types it, adds her email
/// near the end, and closes on the success screen carrying her plan. The
/// first question feels like the start of a membership rather than a form.
///
/// Each new letter "engraves" the whole name (a soft rise and a light
/// sweeping across the card) instead of animating letters one by one,
/// which would break the joins of Arabic script.
class MemberCard extends StatefulWidget {
  const MemberCard({
    required this.name,
    this.email,
    this.details,
    this.active = false,
    super.key,
  });

  final String name;

  /// Null hides the email row; an empty value previews where it will go.
  final String? email;

  /// A line under her contact details, e.g. her plan on the success screen.
  final String? details;

  final bool active;

  static const aspectRatio = 1.9;

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(MemberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final grew =
        widget.name.length > oldWidget.name.length ||
        (widget.email?.length ?? 0) > (oldWidget.email?.length ?? 0);
    if (grew && !MediaQuery.disableAnimationsOf(context)) {
      unawaited(_shine.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = widget.name.trim();
    final white70 = Colors.white.withValues(alpha: 0.72);

    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxWidth / MemberCard.aspectRatio,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [AppColors.primary, AppColors.primaryDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                const Positioned.fill(
                  child: FlowBackground(
                    colors: [
                      Color(0xFFF2A7BC),
                      Color(0xFFF7C6A9),
                      Colors.white,
                    ],
                    strength: 0.28,
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) => _shine.isAnimating
                        ? CustomPaint(painter: _ShinePainter(_shine.value))
                        : const SizedBox.shrink(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'traininpink',
                            style: text.titleLarge!.copyWith(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const Spacer(),
                          _Pill(
                            label: widget.active
                                ? l10n.memberCardActive
                                : l10n.memberCardMember,
                            icon: widget.active ? Icons.check_rounded : null,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.memberCardName,
                              style: text.labelSmall!.copyWith(
                                color: white70,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _EngravedText(
                              value: name.isEmpty ? '— — —' : name,
                              style: text.headlineMedium!.copyWith(
                                color: name.isEmpty ? white70 : Colors.white,
                                fontSize: 28,
                              ),
                            ),
                            if (widget.email case final email?) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.mail_outline_rounded,
                                    size: 15,
                                    color: white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _EngravedText(
                                      value: email.trim().isEmpty
                                          ? '— — —'
                                          : email.trim(),
                                      direction: TextDirection.ltr,
                                      style: text.bodySmall!.copyWith(
                                        color: white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.details case final details?) ...[
                              const SizedBox(height: 4),
                              Text(
                                details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall!.copyWith(color: white70),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EngravedText extends StatelessWidget {
  const _EngravedText({
    required this.value,
    required this.style,
    this.direction,
  });

  final String value;
  final TextStyle style;
  final TextDirection? direction;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(value),
    tween: Tween(begin: 0, end: 1),
    duration: AppMotion.medium,
    curve: AppMotion.emphasized,
    builder: (context, t, child) => Opacity(
      opacity: 0.55 + 0.45 * t,
      child: Transform.translate(
        offset: Offset(0, 4 * (1 - t)),
        child: child,
      ),
    ),
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: direction,
      textAlign: Directionality.of(context) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      style: style,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?) ...[
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}

/// A diagonal band of light sweeping across the card.
class _ShinePainter extends CustomPainter {
  const _ShinePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.4 + t * size.width * 1.8;
    final rect = Rect.fromLTWH(x - 60, 0, 120, size.height);
    canvas
      ..save()
      ..translate(rect.center.dx, rect.center.dy)
      ..skew(-0.35, 0)
      ..translate(-rect.center.dx, -rect.center.dy)
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.28 * (1 - t * 0.5)),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) => oldDelegate.t != t;
}
