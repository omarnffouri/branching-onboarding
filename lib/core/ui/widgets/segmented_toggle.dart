import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';

/// A pill switch between a few options, e.g. Front | Back. The selected
/// segment lifts onto a card; the rest sit on the track.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Each value and its label, in display order.
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget segment(T value, String label) {
      final isSelected = value == selected;
      return Semantics(
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        child: Pressable(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: isSelected ? AppShadows.card : null,
            ),
            child: Text(
              label,
              style: text.labelLarge!.copyWith(
                color: isSelected ? AppColors.primaryDeep : AppColors.inkMuted,
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
          for (final MapEntry(key: value, value: label) in options.entries)
            segment(value, label),
        ],
      ),
    );
  }
}
