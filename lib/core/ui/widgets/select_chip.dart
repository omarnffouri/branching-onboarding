import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';

/// A pill that toggles on and off, for picking several of a set. Shows +
/// until picked, then a check, and is announced as a checkable button.
class SelectChip extends StatelessWidget {
  const SelectChip({
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
