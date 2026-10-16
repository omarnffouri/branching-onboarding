import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';

/// A CTA that stays put while the content scrolls under a soft fade.
class PinnedFooter extends StatelessWidget {
  const PinnedFooter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.background,
      boxShadow: [
        BoxShadow(
          color: AppColors.background,
          blurRadius: 24,
          spreadRadius: 8,
          offset: Offset(0, -12),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: child,
      ),
    ),
  );
}
