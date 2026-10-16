import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';

/// The thin progress bar from the Traininpink onboarding.
///
/// It always animates from where it was to where it is, including when a
/// changed answer makes her path longer or shorter: the bar eases back
/// instead of jumping. Fills from the start edge, so right to left in Arabic.
class FlowProgressBar extends StatelessWidget {
  const FlowProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.clamp(0, 1)),
    duration: AppMotion.slow,
    curve: AppMotion.emphasized,
    builder: (context, animated, _) => Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: animated,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        ),
      ),
    ),
  );
}
