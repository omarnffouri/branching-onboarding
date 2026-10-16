import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// Visible boundaries make every answer tappable before one is selected.
/// Wrapping keeps longer labels readable in Arabic and at larger text sizes.
class RoutineSelector extends StatelessWidget {
  const RoutineSelector({
    required this.options,
    required this.selected,
    required this.language,
    required this.onSelected,
    super.key,
  });

  final List<ChoiceOption> options;
  final String? selected;
  final String language;
  final ValueChanged<ChoiceOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.medium;
    final animation = AnimationStyle(
      duration: duration,
      reverseDuration: duration,
      curve: AppMotion.standard,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label.resolve(language)),
            selected: option.id == selected,
            onSelected: (_) {
              HapticFeedback.selectionClick().ignore();
              onSelected(option);
            },
            // Reserve the same icon space in both states so selection
            // cannot make the chips reflow into different rows.
            avatar: Icon(
              option.id == selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: option.id == selected
                  ? AppColors.primary
                  : AppColors.primarySoft,
            ),
            avatarBoxConstraints: const BoxConstraints.tightFor(
              width: 20,
              height: 20,
            ),
            showCheckmark: false,
            labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: option.id == selected
                  ? AppColors.primaryDeep
                  : AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
            labelPadding: const EdgeInsetsDirectional.fromSTEB(6, 4, 4, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.blush,
            side: BorderSide(
              color: option.id == selected
                  ? AppColors.primary
                  : AppColors.primarySoft,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            chipAnimationStyle: ChipAnimationStyle(
              enableAnimation: animation,
              selectAnimation: animation,
              avatarDrawerAnimation: animation,
            ),
          ),
      ],
    );
  }
}
