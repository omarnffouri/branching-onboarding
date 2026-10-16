import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';

/// An answer card in the Traininpink style: white, rounded, radio at the
/// start. Selection animates the colour, never the size, so nothing in the
/// list shifts by a pixel when she taps.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.multiSelect = false,
    super.key,
  });

  final String label;
  final String? description;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      checked: multiSelect ? selected : null,
      inMutuallyExclusiveGroup: !multiSelect,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          padding: const EdgeInsetsDirectional.fromSTEB(18, 17, 18, 17),
          decoration: BoxDecoration(
            color: selected ? AppColors.blush : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              if (multiSelect)
                CheckIndicator(selected: selected)
              else
                RadioIndicator(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.titleMedium),
                    if (description case final description?) ...[
                      const SizedBox(height: 2),
                      Text(description, style: theme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The radio from a [ChoiceCard], reused by the paywall's plan cards.
class RadioIndicator extends StatelessWidget {
  const RadioIndicator({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.medium,
    curve: AppMotion.standard,
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        width: 1.6,
      ),
    ),
    alignment: Alignment.center,
    child: AnimatedScale(
      scale: selected ? 1 : 0,
      duration: AppMotion.medium,
      curve: selected ? AppMotion.emphasized : Curves.easeIn,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class CheckIndicator extends StatelessWidget {
  const CheckIndicator({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.medium,
    curve: AppMotion.standard,
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        width: 1.6,
      ),
    ),
    child: AnimatedScale(
      scale: selected ? 1 : 0,
      duration: AppMotion.medium,
      curve: selected ? AppMotion.emphasized : Curves.easeIn,
      child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
    ),
  );
}
