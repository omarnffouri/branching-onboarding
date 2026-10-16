import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';

/// The call to action, "Continue →".
///
/// The arrow is a directional icon, so it points left in Arabic without any
/// special casing. When the label changes (e.g. picking another plan on the
/// paywall) it cross-fades instead of snapping.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.showArrow = true,
    this.haptic = PressHaptic.light,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showArrow;
  final PressHaptic haptic;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge!.copyWith(color: Colors.white);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onPressed,
        pressedScale: 0.98,
        haptic: haptic,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          height: 58,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(AppRadii.button),
            boxShadow: enabled ? AppShadows.raised : const [],
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(label),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showArrow) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
